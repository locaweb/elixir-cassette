defmodule Cassette.Server do
  @moduledoc """
  The GenServer that maintains the CAS cache in its state
  """

  use GenServer

  import Cassette.Version, only: [version: 2]

  alias Cassette.Authentication
  alias Cassette.Client
  alias Cassette.Client.ValidateTicket
  alias Cassette.Config
  alias Cassette.Server.State
  alias Cassette.User

  require Cassette.Version

  @typep tgt_request :: {:tgt, non_neg_integer()}

  @typep st_request :: {:st, String.t(), String.t(), non_neg_integer()}

  @typep validate_request :: {:validate, String.t(), String.t(), non_neg_integer()}

  @typep reload_request :: {:reload, Config.t()}

  @typep config_request :: {:config}

  @typep cassette_request ::
           tgt_request
           | st_request
           | validate_request
           | config_request
           | reload_request

  @typep tgt_reply :: {:ok, String.t()} | {:error, term}

  @typep st_reply :: {:ok, String.t()} | {:error, term}

  @typep validate_reply :: {:ok, User.t()} | {:error, term}

  @typep reload_reply :: :ok

  @typep config_reply :: Config.t()

  @typep cassette_reply ::
           tgt_reply
           | st_reply
           | validate_reply
           | config_reply
           | reload_reply

  @doc false
  @spec start_link(term, Config.t()) :: GenServer.on_start()
  def start_link(name, config) do
    GenServer.start_link(__MODULE__, {:ok, config}, name: name)
  end

  @doc false
  @spec start_link(Config.t()) :: GenServer.on_start()
  def start_link(config) do
    GenServer.start_link(__MODULE__, {:ok, config})
  end

  version(">= 1.5.0") do
    def child_spec([name, config = %Config{}]) do
      defaults = %{id: name, start: {__MODULE__, :start_link, [name, config]}}
      Supervisor.child_spec(defaults, [])
    end
  end

  @doc """
  Validates a `ticket` for the given `service`
  """
  @spec validate(GenServer.server(), String.t(), String.t(), timeout()) ::
          {:ok, User.t()}
          | {:error, term}
  def validate(server, ticket, service, timeout \\ 5000) do
    GenServer.call(server, {:validate, ticket, service, time_now()}, timeout)
  end

  @doc """
  Generates a Ticket Granting Ticket based on the configuration of the `server`
  """
  @spec tgt(GenServer.server(), timeout()) :: {:ok, String.t()} | {:error, term}
  def tgt(server, timeout \\ 5000) do
    GenServer.call(server, {:tgt, time_now()}, timeout)
  end

  @doc """
  Generates Service Ticket based on the configuration of the `server` and the
  given `tgt`
  """
  @spec st(GenServer.server(), String.t(), String.t(), timeout()) ::
          {:ok, String.t()}
          | {:error, term}
  def st(server, current_tgt, service, timeout \\ 5000) do
    GenServer.call(server, {:st, current_tgt, service, time_now()}, timeout)
  end

  @doc """
  Returns this server's current configuration
  """
  @spec config(GenServer.server()) :: Config.t()
  def config(server) do
    GenServer.call(server, {:config})
  end

  @doc """
  Initializes the server with the given configuration
  """
  @spec init({:ok, Config.t()}) :: {:ok, State.t()}
  def init({:ok, config}) do
    {:ok, %State{config: Config.resolve(config)}}
  end

  @doc """
  Changes the internal state configuration to `config`
  """
  @spec reload(GenServer.server(), Config.t()) :: term
  def reload(server, config) do
    GenServer.call(server, {:reload, config})
  end

  @spec handle_call(cassette_request, GenServer.from(), State.t()) ::
          {:reply, cassette_reply, State.t()}
  def handle_call(
        {:validate, ticket, service, now},
        _from,
        state = %State{validations: validations, config: config}
      ) do
    cached_value = Map.get(validations, {service, ticket})

    case evaluate_validation(config, service, ticket, cached_value, now) do
      {:ok, user, expires_at, new} ->
        if new do
          Process.send_after(
            self(),
            {:expire, :validation, {service, ticket}},
            trunc(config.validation_ttl * 1000)
          )
        end

        new_state = State.put_validation(state, {service, ticket}, {user, expires_at})
        {:reply, {:ok, user}, new_state}

      reply ->
        {:reply, reply, state}
    end
  end

  def handle_call({:config}, _from, state = %State{config: config}) do
    {:reply, config, state}
  end

  def handle_call(
        {:st, current_tgt, service, now},
        _from,
        state = %State{config: config, tgt: {:tgt, _, current_tgt}, sts: sts}
      ) do
    cached_value = Map.get(sts, service)

    case evaluate_st(config, current_tgt, service, cached_value, now) do
      {:ok, new_st, expires_at} ->
        new_state = State.put_st(state, service, {new_st, expires_at})
        {:reply, {:ok, new_st}, new_state}

      reply = {:error, :tgt_expired} ->
        {:reply, reply, State.clear_tgt(state)}

      reply ->
        {:reply, reply, state}
    end
  end

  def handle_call({:tgt, now}, _from, state = %State{config: config, tgt: current_tgt})
      when now > elem(current_tgt, 1) do
    case Client.tgt(config) do
      {:ok, new_tgt} ->
        new_state = State.put_tgt(state, new_tgt, time_now() + config.tgt_ttl)
        {:reply, {:ok, new_tgt}, new_state}

      {:error, :bad_credentials} ->
        {:reply, {:error, "Bad credentials"}, state}

      {:fail, :unknown} ->
        {:reply, {:error, "Failed for unknown reason"}, state}

      {:fail, status_code} ->
        {:reply, {:error, "Failed with status #{status_code}"}, state}
    end
  end

  def handle_call({:tgt, _}, _from, state = %State{tgt: {:tgt, _, tgt}}) do
    {:reply, {:ok, tgt}, state}
  end

  def handle_call({:reload, config = %Config{}}, _from, _state) do
    {:ok, state} = init({:ok, config})
    {:reply, :ok, state}
  end

  def handle_info({:expire, :validation, key}, state) do
    state = State.delete_validation(state, key)
    {:noreply, state}
  end

  @spec evaluate_validation(Config.t(), String.t(), String.t(), State.st(), non_neg_integer()) ::
          {:ok, User.t(), non_neg_integer(), boolean()} | {:error, term}

  defp evaluate_validation(_, _, _, {user, expires_at}, now)
       when now < expires_at do
    {:ok, user, expires_at, false}
  end

  defp evaluate_validation(config, service, ticket, _, _) do
    reply =
      case ValidateTicket.perform(config, ticket, service) do
        {:ok, body} -> Authentication.handle_response(body)
        {:fail, reason} -> {:error, reason}
      end

    case reply do
      {:ok, user} ->
        {:ok, user, time_now() + config.validation_ttl, true}

      reply ->
        reply
    end
  end

  @spec evaluate_st(Config.t(), String.t(), String.t(), State.st(), non_neg_integer()) ::
          {:ok, String.t(), non_neg_integer()}
  defp evaluate_st(_, _, _, {current_st, expires_at}, now)
       when now < expires_at do
    {:ok, current_st, expires_at}
  end

  @spec evaluate_st(Config.t(), String.t(), String.t(), State.st(), non_neg_integer()) ::
          {:ok, String.t(), non_neg_integer()} | {:error, term}
  defp evaluate_st(config, current_tgt, service, _, _) do
    case Client.st(config, current_tgt, service) do
      {:ok, new_st} ->
        {:ok, new_st, time_now() + config.st_ttl}

      {:error, :bad_tgt} ->
        {:error, :tgt_expired}

      {:fail, status_code, body} ->
        {:error, "Failed with status #{status_code}: #{body}"}

      {:fail, :unknown} ->
        {:error, "Failed for unknown reason"}
    end
  end

  @spec time_now :: non_neg_integer()
  defp time_now do
    :calendar.datetime_to_gregorian_seconds(:calendar.local_time())
  end
end
