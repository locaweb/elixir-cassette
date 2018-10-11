defmodule Cassette.ConfigTest do
  use ExUnit.Case, async: false

  alias Cassette.Config

  test "default/0 when reading from environment variables" do
    System.put_env("CASSETTE_PASSWORD", "asupersecret")
    assert {:system, "CASSETTE_PASSWORD"} != Application.get_env(:cassette, :password)
    {:ok, current_password} = Application.fetch_env(:cassette, :password)
    Application.put_env(:cassette, :password, {:system, "CASSETTE_PASSWORD"})

    assert "asupersecret" = Config.default().password

    System.delete_env("CASSETTE_PASSWORD")
    Application.put_env(:cassette, :password, current_password)
  end

  test "default/0 when reading from environment variables with fallback to the default" do
    assert System.get_env("CASSETTE_BASE") == nil
    {:ok, current_base} = Application.fetch_env(:cassette, :base_url)
    Application.put_env(:cassette, :base_url, {:system, "CASSETTE_BASE"})

    assert "" = Config.default().base_url

    Application.put_env(:cassette, :base_url, current_base)
  end

  test "default/0.insecure when insecure is not configured returns false" do
    Application.delete_env(:cassette, :insecure)

    refute Config.default().insecure
  end

  test "default/0.insecure when insecure is set to true returns true" do
    Application.put_env(:cassette, :insecure, true)

    assert Config.default().insecure
  end

  test "default/0.insecure when insecure is set to true returns false" do
    Application.put_env(:cassette, :insecure, false)

    refute Config.default().insecure
  end

  test "default/0 when tgt_ttl is not configured" do
    Application.delete_env(:cassette, :tgt_ttl)

    assert Config.default().tgt_ttl == 14_400
  end

  test "default/0 when st_ttl is not configured" do
    Application.delete_env(:cassette, :st_ttl)

    assert Config.default().st_ttl == 252
  end

  test "default/0 when validation_ttl is not configured" do
    Application.delete_env(:cassette, :validation_ttl)

    assert Config.default().validation_ttl == 300
  end

  test "default/0 when tgt_ttl is configured" do
    Application.put_env(:cassette, :tgt_ttl, 42)

    assert Config.default().tgt_ttl == 42
  end

  test "default/0 when st_ttl is configured" do
    Application.put_env(:cassette, :st_ttl, 42)

    assert Config.default().st_ttl == 42
  end

  test "default/0 when validation_ttl is configured" do
    Application.put_env(:cassette, :validation_ttl, 42)

    assert Config.default().validation_ttl == 42
  end

  test "default/0 should allow values to be overriden to nil" do
    base_authority = Application.get_env(:cassette, :base_authority)
    Application.put_env(:cassette, :base_authority, nil)
    refute is_nil(base_authority)

    assert is_nil(Config.default().base_authority)

    Application.put_env(:cassette, :base_authority, base_authority)
  end

  test "resolve/1 when reading from a environment variable that does not exist returns the default value" do
    config = %{Config.default() | base_authority: {:system, "CASSETTE_TEST_BASE_AUTHORITY"}}

    assert %Config{base_authority: ""} = Config.resolve(config)
  end

  test "resolve/1 when reading from a environment variable that exists use the env var value" do
    System.put_env("CASSETTE_TEST_BASE_AUTHORITY", "test_base_authority")
    config = %{Config.default() | base_authority: {:system, "CASSETTE_TEST_BASE_AUTHORITY"}}

    assert %Config{base_authority: "test_base_authority"} = Config.resolve(config)

    System.delete_env("CASSETTE_TEST_BASE_AUTHORITY")
  end
end
