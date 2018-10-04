defmodule FakeCas.Support do
  @moduledoc """
  Cassette support files for FakeCas.

  Provides convience functions for test and development using a stubbed Cas
  server.
  """

  @doc "Starts the server and configure `Cassette` to use it"
  @spec initialize :: :ok
  def initialize do
    FakeCas.start()
    configure_cassette()
    Cassette.reload()
  end

  @doc "Returns a modified `Cassette.Config.t` to use `FakeCas` settings"
  @spec config :: Cassette.Config.t()
  def config do
    %{
      Cassette.Config.default()
      | username: FakeCas.valid_username(),
        password: FakeCas.valid_password(),
        base_url: "http://localhost:#{FakeCas.port()}"
    }
  end

  @doc "Configures Cassette env using FakeCas settings"
  @spec configure_cassette :: :ok
  def configure_cassette do
    Application.ensure_all_started(:bypass)
    GenServer.stop(:CassetteServer)

    FakeCas.Support.config()
    |> Map.delete(:__struct__)
    |> Enum.each(fn {k, v} -> Application.put_env(:cassette, k, v) end)

    :ok
  end
end
