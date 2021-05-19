# Cassette

Library to generate and validate [CAS](http://jasig.github.io/cas/) TGTs/STs

[![Test and quality](https://github.com/locaweb/elixir-cassette/actions/workflows/main.yml/badge.svg)](https://github.com/locaweb/elixir-cassette/actions/workflows/main.yml)

## Installation

The package can be installed as:

  1. Add cassette to your list of dependencies in `mix.exs`:

        def deps do
          [{:cassette, "~> 1.1"}]
        end

  2. Ensure cassette is started before your application:

        def application do
          [applications: [:cassette]]
        end


## Usage with the default configuration

The module `Cassette` includes the functions to generate TGTs and STs

This will use the default configuration (in mix.config), please refer to `Cassete.Config` struct for the available keys (including expiration times).

```elixir
config :cassette, username: "example-user"
config :cassette, password: "topsecret"
config :cassette, base_url: "https://cas-server.example.org"
config :cassette, base_authority: "EXAMPLE"
config :cassette, service: "app.example.org"
```

`base_authority` helps on role validation and `service` is the default value used by `Cassette.validate/2`

This default configuration is returned by the `Cassette.Config.default` function.

Any of those values may be configured with a tuple, so configuration can be loaded using environment variables:

```elixir
config :cassette, password: {:system, "SOME_ENVIRONMENT_VARIABLE"}
```

A round trip validation would look like this:

    $ iex -S mix

    iex> {:ok, tgt} = Cassette.tgt
    {:ok, "TGT-11692539-ZIvKZ6TlGUBX5DBgR6egYnVvJeHyJpM2oxApxlsIYEaX2dUd9x"}

    iex> {:ok, st} = Cassette.st(Cassette.Config.default.service)
    {:ok, "ST-16175889-oqcTdH041YZeeLcQtYCL"}

    iex> Cassette.validate(st, Cassette.Config.default.service)
    {:ok, %Cassette.User{login: "sampleuser", authorities: ["ACME_ADMIN"...]}}


You are not required to call `Cassette.tgt`, it will be generated (or re-generated in case of expiration) when creating a ST.

## Multiple configurations

If you want to use multiple cas services you can create your own module and `use` the `Cassette.Support` macro module, you can define the `GenServer` name and/or provide a configuration.

```elixir
defmodule MyCas do
  use Cassette.Support, process_name: :MyCasServer, config: %Cassette.Config{...}
end
```

This other Cas service must be started as well with `MyCas.start` before it can be used or it may be added to your supervision tree:

```elixir
defmodule YourApp do
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # some other apps,
      MyCas.child_spec
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.started(children, opts)
  end
end
```

## Using self signed servers


If you really really want to use insecure/self-signed certificates, use a `Cassette.Config` struct with `insecure` set to true.
You can also define in your `mix/config.exs` like:

```elixir
use Mix.Config

config :cassette, :insecure, true
```

## Contributing

Check out [Contributing](CONTRIBUTING.md) guide.
