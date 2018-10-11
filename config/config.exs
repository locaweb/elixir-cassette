# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :cassette, username: "example"
config :cassette, password: "supersecret"
config :cassette, base_url: "https://cas.example.org"
config :cassette, base_authority: "EXAMPLE"
config :cassette, service: "app.example.org"

import_config "#{Mix.env()}.exs"
