defmodule Cassette.UserTest do
  use ExUnit.Case, async: true

  alias Cassette.Config
  alias Cassette.User

  test "has_role?/2 returns true when the user has the authority" do
    config = Config.default()
    user = User.new("example", ["#{config.base_authority}_BLA"])

    assert User.has_role?(user, "BLA")
  end

  test "has_role?/2 returns false when the user does not have the authority" do
    config = Config.default()
    user = User.new("example", ["#{config.base_authority}_BLA"])

    refute User.has_role?(user, "BLI")
  end

  test "has_role?/3 returns true when the user has the authority" do
    user = User.new("example", ["TEST_BLA"])
    config = %Config{base_authority: "TEST"}

    assert User.has_role?(user, config, "BLA")
  end

  test "has_role?/3 returns false when the user does not have the authority (with the same base authority)" do
    user = User.new("example", ["EXAMPLE_BLA"])
    config = %Config{base_authority: "TEST"}

    refute User.has_role?(user, config, "BLA")
  end

  test "has_role?/3 returns false when the user does not have the authority" do
    user = User.new("example", ["TEST_BLA"])
    config = %Config{base_authority: "TEST"}

    refute User.has_role?(user, config, "BLI")
  end

  test "has_raw_role? returns true when user has the autority" do
    user = User.new("example", ["BLA", "BLE"])

    assert User.has_raw_role?(user, "BLA")
  end

  test "has_raw_role? returns false when user does not have the autority" do
    user = User.new("example", ["BLE", "BLI"])

    refute User.has_raw_role?(user, "BLA")
  end

  test "has_role?/2 returns false when user is not a Cassette.User" do
    refute User.has_role?(nil, "BLA")
  end

  test "has_role?/3 returns false when user is not a Cassette.User" do
    config = %Config{base_authority: "TEST"}
    refute User.has_role?(nil, config, "BLA")
  end

  test "has_raw_role? returns false when user is not a Cassette.User" do
    refute User.has_raw_role?(nil, "BLA")
  end

  test "new/3 downcases the user type" do
    assert "employee" = User.new("example", "Employee", ["EXAMPLE"]).type
    assert "employee" = User.new("example", "EMPLOYEE", ["EXAMPLE"]).type
  end
end
