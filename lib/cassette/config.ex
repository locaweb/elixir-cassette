defmodule Cassette.Config do
  @moduledoc """
  Struct that represents Cassette configuration
  """

  defstruct username: "",
            password: "",
            base_url: "",
            base_authority: "",
            service: "",
            tgt_ttl: 14_400,
            st_ttl: 252,
            validation_ttl: 300,
            insecure: false

  @typedoc """
  The following keys are supported and may be defined in your application env

  * `username` - the username to authenticate on cas server
  * `password` - the password to authenticate on cas server
  * `base_url` - the base url for your CAS server (do not include the `login/`)
  * `base_authority` - simplifies role checking, please refer to
    `Cassette.User.role?/2`
  * `service` - the CAS service to use when validating service tickets
  * `tgt_ttl` - the TGT cache time to live
  * `st_ttl` - the ST cache time to live
  * `validation_ttl` - the ST validation cache time to live
  * `insecure` - boolean to allow connection even with ssl check failures

  Any of those keys may be set in your Application environment
  (or the mix `config/config.exs`) as:

  ```elixir
  config :cassette, username: "john.doe"
  ```

  `Cassette.Server`s call the `resolve/1` function on this module to resolve any
  configuration using environment variables.
  To use an environment variable set the value to
  `{:system, "SOME_ENVIRONMENT_VARIABLE"}`.

  Or in `config.exs`:

  ```elixir
  config :cassette, username: {:system, "CASSETTE_USERNAME"}
  ``

  and configure your environment (provabably in something like
  `/etc/default/your_app`):

  ```shell
  CASSETTE_USERNAME=acme
  ```

  Please check the `Cassette.Config.default/0` function.

  """
  @type t :: %__MODULE__{
          username: String.t(),
          password: String.t(),
          base_url: String.t(),
          base_authority: String.t(),
          service: String.t(),
          tgt_ttl: non_neg_integer(),
          st_ttl: non_neg_integer(),
          validation_ttl: non_neg_integer()
        }

  @doc """
  Returns a configuration based on what is set in application environment and
  default values

  Check `Cassette.Config.t` for key details
  """
  @spec default() :: t
  def default do
    default_values = %Cassette.Config{}

    env_or_default = fn key ->
      case Application.fetch_env(:cassette, key) do
        {:ok, {:system, var}} ->
          System.get_env(var) || Map.get(default_values, key)

        {:ok, value} ->
          value

        :error ->
          Map.get(default_values, key)
      end
    end

    default_values
    |> Map.keys()
    |> Enum.reduce(default_values, &Map.put(&2, &1, env_or_default.(&1)))
  end

  @doc """
  Resolves config by fetching environment variables when values are in the form:

  ```elixir
  {:system, "SOME_ENVIRONMENT_VARIABLE"}

  ```

  The value will be fetched from the `SOME_ENVIRONMENT_VARIABLE` variable.
  If that variable is `nil`, the default value in `Cassette.Config.t` will be
  used
  """
  @spec resolve(t) :: t
  def resolve(config = %Cassette.Config{}) do
    default_values = %Cassette.Config{}

    resolve_env_var = fn
      key, {:system, var} ->
        {key, System.get_env(var) || Map.get(default_values, key)}

      key, value ->
        {key, value}
    end

    env_or_default = fn map ->
      fn key ->
        resolve_env_var.(key, Map.get(map, key))
      end
    end

    config
    |> Map.keys()
    |> Enum.into(%{}, env_or_default.(config))
  end

  def resolve(nil), do: default()
end
