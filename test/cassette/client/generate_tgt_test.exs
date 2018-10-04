defmodule Cassette.Client.GenerateTgtTest do
  use ExUnit.Case, async: true

  alias Plug.Conn

  alias Cassette.Client.GenerateTgt
  alias Cassette.Config

  setup do
    bypass = Bypass.open()
    base_url = "http://localhost:#{bypass.port}"
    config = %{Config.default() | base_url: base_url}

    {:ok, bypass: bypass, config: config}
  end

  test "perform returns :bad_credentials for a 400 response", %{bypass: bypass, config: config} do
    Bypass.expect(bypass, fn conn ->
      Conn.resp(conn, 400, "bad bad bad")
    end)

    assert {:error, :bad_credentials} = GenerateTgt.perform(config)
  end

  test "perform returns {:fail, status_code} for other error statuses", %{
    bypass: bypass,
    config: config
  } do
    Bypass.expect(bypass, fn conn ->
      Conn.resp(conn, 404, "not found")
    end)

    assert {:fail, 404} = GenerateTgt.perform(config)
  end

  test "perform generates a TGT", %{bypass: bypass, config: config} do
    tgt = "TGT-bla"
    location = "#{config.base_url}/v1/tickets/#{tgt}"

    Bypass.expect(bypass, fn conn ->
      assert "/v1/tickets" == conn.request_path
      assert "POST" == conn.method

      conn
      |> Conn.put_resp_header("Location", location)
      |> Conn.resp(201, "")
    end)

    assert {:ok, ^tgt} = GenerateTgt.perform(config)
  end
end
