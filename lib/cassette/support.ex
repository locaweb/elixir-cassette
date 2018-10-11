defmodule Cassette.Support do
  @moduledoc """
  This macro module allows you to create your own Cassette service with custom
  configurations

  You can customize the (otp) application name with the `:process_name` key and
  provide your configuration in the `:config` key.

  ```elixir
  defmodule MyCas do
    use Cassette.Support, process_name: :EmployeesCas, config:
      %{Cassette.Config.default | base_url: "https://employees-cas.example.org"}
  end
  ```

  Please refer to `Cassette` for usage

  """

  alias Cassette.Config
  alias Cassette.Server
  alias Cassette.User

  import Cassette.Version, only: [version: 2]

  require Cassette.Version

  @type t :: module()

  defmacro __using__(opts \\ []) do
    quote bind_quoted: [opts: opts] do
      @name opts[:process_name] || :CassetteServer
      @config opts[:config] || %{}

      @spec stop(term) :: term
      def stop(_state) do
        GenServer.stop(@name)
      end

      @spec start() :: GenServer.on_start()
      def start do
        config =
          Config.default()
          |> Map.merge(@config)
          |> Config.resolve()

        version ">= 1.5.0" do
          children = [{Server, [@name, config]}]
        else
          import Supervisor.Spec
          children = [worker(Server, [@name, config])]
        end

        options = [strategy: :one_for_one, name: :"#{@name}.Supervisor"]

        case Supervisor.start_link(children, options) do
          {:ok, pid} -> {:ok, pid}
          {:error, {:already_started, pid}} -> {:ok, pid}
          other -> other
        end
      end

      @doc """
      Elixir 1.5+ compatible child spec.

      If you are adding a custom cassette instance, you can add to your
      supervision tree by using:

      ```elixir

      defmodule MyCas do
        use Cassette.Support, process_name: :MyCas
      end

      children = [
        # ...
        MyCas
      ]

      Supervisor.start_link(children, ...)
      ```

      """
      @spec child_spec(term) :: :supervisor.child_spec()
      def child_spec(_opts) do
        %{
          id: @name,
          start: {__MODULE__, :start, []},
          restart: :permanent,
          type: :supervisor
        }
      end

      @doc """
      Generates a child spec for a custom Cassette module for Elixir < 1.5

      If you are adding a custom cassette instance, you can add to your
      supervision tree by using:

      ```elixir

      defmodule MyCas do
        use Cassette.Support, process_name: :MyCas
      end

      children = [
        # ...
        MyCas.child_spec
      ]

      Supervisor.start_link(children, ...)
      ```

      """

      @spec child_spec() :: Supervisor.Spec.spec()
      def child_spec do
        mod = __MODULE__
        {mod, {mod, :start, []}, :permanent, :infinity, :supervisor, [mod]}
      end

      @doc """
      Returns the configuration used by this Cassette server

      Will return the default configuration if not provided.

      Please refer to `Cassette.Config.t` for details
      """
      @spec config :: Config.t()
      def config do
        Server.config(@name)
      end

      @doc """
      Generates a Ticket Granting Ticket
      """
      @spec tgt(timeout()) :: {:ok, String.t()} | {:error, term}
      def tgt(timeout \\ 5000) do
        Server.tgt(@name, timeout)
      end

      @doc """
      Generates a Service Ticket for the given `service`

      This function retries once when the TGT is expired on the server side.
      """
      @spec st(String.t(), timeout()) :: {:ok, String.t()} | {:error, term}
      def st(service, timeout \\ 5000) do
        {:ok, current_tgt} = tgt()

        case Server.st(@name, current_tgt, service, timeout) do
          {:error, :tgt_expired} ->
            {:ok, new_tgt} = tgt()
            Server.st(@name, new_tgt, service, timeout)

          reply ->
            reply
        end
      end

      @doc """
      Validates a given `ticket` against the given `service` or the service set
      in the configuration
      """
      @spec validate(String.t(), String.t(), timeout()) :: {:ok, User.t()} | {:error, term}
      def validate(ticket, service \\ config().service, timeout \\ 5000) do
        Server.validate(@name, ticket, service, timeout)
      end

      @doc false
      @spec reload(Config.t()) :: term
      def reload(cfg \\ Config.default()) do
        Server.reload(@name, cfg)
      end
    end
  end
end
