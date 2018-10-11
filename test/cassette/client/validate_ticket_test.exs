defmodule Cassette.Client.ValidateTicketTest do
  use ExUnit.Case, async: true

  alias Plug.Conn
  alias Plug.Parsers

  alias Cassette.Client.ValidateTicket
  alias Cassette.Config

  setup do
    bypass = Bypass.open()
    base_url = "http://localhost:#{bypass.port}"
    config = %{Config.default() | base_url: base_url}
    service = "api.example.org"
    ticket = "ST-something"

    {:ok, bypass: bypass, config: config, ticket: ticket, service: service}
  end

  test "perform returns {:fail, :unknown} for not-200 response", %{
    bypass: bypass,
    config: config,
    ticket: ticket,
    service: service
  } do
    Bypass.expect(bypass, fn conn ->
      Conn.resp(conn, 404, "not found")
    end)

    assert {:fail, :unknown} = ValidateTicket.perform(config, ticket, service)
  end

  test "perform returns {:fail, :unknown} then http fails", %{
    bypass: bypass,
    config: config,
    ticket: ticket,
    service: service
  } do
    Bypass.down(bypass)

    assert {:fail, :unknown} = ValidateTicket.perform(config, ticket, service)
  end

  test "perform returns the validation body", %{
    bypass: bypass,
    config: config,
    ticket: ticket,
    service: service
  } do
    body = "<validation><result><xml /></result></validation>"

    Bypass.expect(bypass, fn c ->
      conn = Parsers.call(c, Parsers.init(parsers: [:urlencoded]))

      assert "/serviceValidate" == conn.request_path
      assert "GET" == conn.method
      assert conn.query_params["ticket"] == ticket
      assert conn.query_params["service"] == service

      Conn.resp(conn, 200, body)
    end)

    assert {:ok, ^body} = ValidateTicket.perform(config, ticket, service)
  end
end
