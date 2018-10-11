defmodule MyCas do
  @moduledoc false

  alias Cassette.Config
  alias Cassette.Support

  use Support,
    process_name: :MyCasServer,
    config: %{
      Config.default()
      | base_authority: "ME",
        password: {:system, "CASSETTE_TEST_PASSWORD"}
    }
end
