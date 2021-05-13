defmodule Cassette.ServerIntegrationTest do
  use ExUnit.Case, async: true

  alias Cassette.Server
  alias Cassette.Server.State

  alias FakeCas.Support

  setup do
    {:ok, _pid} =
      start_supervised(%{
        id: FakeCas,
        start: {FakeCas, :start_link, []}
      })

    config = Support.config()
    {:ok, pid} = Server.start_link(config)

    {:ok, [pid: pid, config: config]}
  end

  test "returns its configuration", %{pid: pid, config: config} do
    assert ^config = Server.config(pid)
  end

  test "generates a correct tgt", %{pid: pid} do
    tgt = FakeCas.valid_tgt()
    assert {:ok, ^tgt} = Server.tgt(pid)
  end

  test "expiring a validation removes it from the cache",
       %{pid: pid, config: config} do
    config = Map.put(config, :validation_ttl, 1 / 1000)
    :ok = Server.reload(pid, config)

    Server.validate(pid, FakeCas.valid_st(), config.service)
    Process.sleep(10)

    assert %State{validations: validations} = :sys.get_state(pid)
    assert validations == %{}
  end

  test "fails with unknown reason when cas is down",
       %{pid: pid, config: config} do
    {:ok, fake_cas_pid} = FakeCas.Server.start_link([])
    port = FakeCas.Server.port(fake_cas_pid)
    config = Map.put(config, :base_url, "http://localhost:#{port}")
    :ok = Cassette.Server.reload(pid, config)
    FakeCas.Server.stop(fake_cas_pid)

    assert {:error, "Failed for unknown reason"} = Server.tgt(pid)
  end

  test "fails with {:error, _} when username/password is invalid",
       %{pid: pid, config: config} do
    config = Map.put(config, :username, config.username <> "42")
    :ok = Server.reload(pid, config)

    assert {:error, "Bad credentials"} = Server.tgt(pid)
  end

  test "generates a st from the tgt", %{pid: pid} do
    st = FakeCas.valid_st()
    {:ok, tgt} = Server.tgt(pid)
    ^tgt = FakeCas.valid_tgt()

    assert {:ok, ^st} = Server.st(pid, FakeCas.valid_tgt(), "service")
  end

  test "generates a st from the tgt (with timeout)", %{pid: pid} do
    st = FakeCas.valid_st()
    {:ok, tgt} = Server.tgt(pid, 6000)
    ^tgt = FakeCas.valid_tgt()

    assert {:ok, ^st} = Server.st(pid, FakeCas.valid_tgt(), "service", 6000)
  end

  test "generates a st from the tgt (with cache)", %{pid: pid} do
    st = FakeCas.valid_st()
    {:ok, tgt} = Server.tgt(pid)
    ^tgt = FakeCas.valid_tgt()

    assert {:ok, ^st} = Server.st(pid, FakeCas.valid_tgt(), "service")
    assert {:ok, ^st} = Server.st(pid, FakeCas.valid_tgt(), "service")
  end

  test "validates a st", %{pid: pid, config: config} do
    {:ok, _} = Server.tgt(pid)

    assert {:ok, %Cassette.User{login: "example"}} =
             Server.validate(pid, FakeCas.valid_st(), config.service)
  end

  test "validates a st (with timeout)", %{pid: pid, config: config} do
    {:ok, _} = Server.tgt(pid, 6000)

    assert {:ok, %Cassette.User{login: "example"}} =
             Server.validate(pid, FakeCas.valid_st(), config.service(), 6000)
  end

  test "validates a st (with cache)", %{pid: pid, config: config} do
    {:ok, _} = Server.tgt(pid)

    assert {:ok, %Cassette.User{login: "example"}} =
             Server.validate(pid, FakeCas.valid_st(), config.service)

    assert {:ok, %Cassette.User{login: "example"}} =
             Server.validate(pid, FakeCas.valid_st(), config.service)
  end

  test "return an {:error, _} for an invalid ticket",
       %{pid: pid, config: config} do
    assert {:error, _} = Server.validate(pid, "some-invalid-ticket", config.service)
  end
end
