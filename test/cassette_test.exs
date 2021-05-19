defmodule CassetteTest do
  use ExUnit.Case
  doctest Cassette

  setup do
    {:ok, _pid} = start_supervised(Cassette)

    {:ok, _pid} =
      start_supervised(%{
        id: FakeCas,
        start: {FakeCas, :start_link, []}
      })

    FakeCas.Support.initialize()

    :ok
  end
end
