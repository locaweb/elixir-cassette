defmodule Cassette.VersionTest do
  use ExUnit.Case

  import Cassette.Version, only: [version: 2]

  require Cassette.Version

  test "it does not emit compiler warnings in the branch not executed" do
    output =
      ExUnit.CaptureIO.capture_io(:stderr, fn ->
        {_code, []} =
          Code.eval_string("""
            require Cassette.Version
            Cassette.Version.version(">= 1.2.0") do
              %{}
            else
              HashDict.new()
            end
          """)
      end)

    refute output =~ "deprecated"
  end

  test "it executes the else block when condition does not match" do
    version("< 1.2.0") do
      assert false, "should not execute this branch"
    else
      assert true, "should execute this branch"
    end
  end

  test "it executes the do block when condition matches" do
    version(">= 1.2.0") do
      assert true, "should execute this branch"
    else
      assert false, "should not execute this branch"
    end
  end
end
