defmodule Cassette.Client.GenerateStTest do
  use ExUnit.Case, async: true

  alias Plug.Conn
  alias Plug.Parsers

  alias Cassette.Client.GenerateSt
  alias Cassette.Config

  setup do
    bypass = Bypass.open()
    base_url = "http://localhost:#{bypass.port}"
    config = %{Config.default() | base_url: base_url}
    service = "api.example.org"
    tgt = "TGT-something"

    {:ok, bypass: bypass, config: config, tgt: tgt, service: service}
  end

  test "perform returns :bad_tgt for a 404 response", %{
    bypass: bypass,
    config: config,
    tgt: tgt,
    service: service
  } do
    Bypass.expect(bypass, fn conn ->
      Conn.resp(conn, 404, "not found")
    end)

    assert {:error, :bad_tgt} = GenerateSt.perform(config, tgt, service)
  end

  test "perform returns {:fail, status_code, body} for other error statuses", %{
    bypass: bypass,
    config: config,
    tgt: tgt,
    service: service
  } do
    Bypass.expect(bypass, fn conn ->
      Conn.resp(conn, 418, "I. am. a. freaking. teapot.")
    end)

    assert {:fail, 418, "I. am. a. freaking. teapot."} = GenerateSt.perform(config, tgt, service)
  end

  test "perform returns {:fail, :unknown} then http fails", %{
    bypass: bypass,
    config: config,
    tgt: tgt,
    service: service
  } do
    Bypass.down(bypass)

    assert {:fail, :unknown} = GenerateSt.perform(config, tgt, service)
  end

  test "perform generates a ST", %{bypass: bypass, config: config, tgt: tgt, service: service} do
    st = "ST-some-service"

    Bypass.expect(bypass, fn c ->
      conn = Parsers.call(c, Parsers.init(parsers: [:urlencoded]))

      assert "/v1/tickets/#{tgt}" == conn.request_path
      assert "POST" == conn.method
      assert conn.body_params["service"] == service

      Conn.resp(conn, 200, st)
    end)

    assert {:ok, ^st} = GenerateSt.perform(config, tgt, service)
  end
end
