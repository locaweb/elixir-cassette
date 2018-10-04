defmodule Cassette.Client.ValidateTicketTest do
  use ExUnit.Case, async: true

  alias Plug.Parsers

  setup do
    bypass = Bypass.open()
    base_url = "http://localhost:#{bypass.port}"
    config = %{Cassette.Config.default() | base_url: base_url}
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
      conn |> Plug.Conn.resp(404, "not found")
    end)

    assert {:fail, :unknown} = Cassette.Client.ValidateTicket.perform(config, ticket, service)
  end

  test "perform returns {:fail, :unknown} then http fails", %{
    bypass: bypass,
    config: config,
    ticket: ticket,
    service: service
  } do
    Bypass.down(bypass)

    assert {:fail, :unknown} = Cassette.Client.ValidateTicket.perform(config, ticket, service)
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

      conn
      |> Plug.Conn.resp(200, body)
    end)

    assert {:ok, ^body} = Cassette.Client.ValidateTicket.perform(config, ticket, service)
  end
end
