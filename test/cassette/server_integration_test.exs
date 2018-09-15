defmodule Cassette.ServerIntegrationTest do
  use ExUnit.Case, async: true

  alias Cassette.Server

  setup do
    config = FakeCas.Support.config
    {:ok, pid} = Cassette.Server.start_link(config)

    {:ok, [pid: pid, config: config]}
  end

  test "returns its configuration", %{pid: pid, config: config} do
    assert ^config = Server.config(pid)
  end

  test "generates a correct tgt", %{pid: pid} do
    tgt = FakeCas.valid_tgt
    assert {:ok, ^tgt} = Server.tgt(pid)
  end

  test "fails when cas is down",
    %{pid: pid, config: config} do

    {:ok, fake_cas_pid} = FakeCas.Server.start_link([])
    port = FakeCas.Server.port(fake_cas_pid)
    config = Map.put(config, :base_url, "http://localhost:#{port}")
    :ok = Cassette.Server.reload(pid, config)
    FakeCas.Server.stop(fake_cas_pid)

    assert {:error, "Failed because econnrefused"} = Server.tgt(pid)
  end

  test "fails with {:error, _} when username/password is invalid",
    %{pid: pid, config: config} do

    config = Map.put(config, :username, config.username <> "42")
    :ok = Server.reload(pid, config)

    assert {:error, "Bad credentials"} = Server.tgt(pid)
  end

  test "generates a st from the tgt", %{pid: pid} do
    st = FakeCas.valid_st
    {:ok, tgt} = Server.tgt(pid)
    ^tgt = FakeCas.valid_tgt

    assert {:ok, ^st} = Server.st(pid, FakeCas.valid_tgt, "service")
  end

  test "generates a st from the tgt (with cache)", %{pid: pid} do
    st = FakeCas.valid_st
    {:ok, tgt} = Server.tgt(pid)
    ^tgt = FakeCas.valid_tgt

    assert {:ok, ^st} = Server.st(pid, FakeCas.valid_tgt, "service")
    assert {:ok, ^st} = Server.st(pid, FakeCas.valid_tgt, "service")
  end

  test "validates a st", %{pid: pid, config: config} do
    {:ok, _} = Server.tgt(pid)

    assert {:ok, %Cassette.User{login: "example"}} =
      Server.validate(pid, FakeCas.valid_st, config.service)
  end

  test "validates a st (with cache)", %{pid: pid, config: config} do
    {:ok, _} = Server.tgt(pid)

    assert {:ok, %Cassette.User{login: "example"}} =
      Server.validate(pid, FakeCas.valid_st, config.service)
    assert {:ok, %Cassette.User{login: "example"}} =
      Server.validate(pid, FakeCas.valid_st, config.service)
  end

  test "return an {:error, _} for an invalid ticket",
    %{pid: pid, config: config} do

    assert {:error, _} =
      Server.validate(pid, "some-invalid-ticket", config.service)
  end
end
