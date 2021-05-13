defmodule Cassette.Mixfile do
  use Mix.Project

  @elixir_version Version.parse!(System.version())

  def version, do: "1.5.3"

  def project do
    [
      app: :cassette,
      version: version(),
      elixir: "~> 1.2",
      description: "A CAS client and validation library",
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      docs: [
        extras: ["README.md", "CONTRIBUTING.md", "LICENSE.md"]
      ],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test, "coveralls.detail": :test, "coveralls.html": :test],
      deps: deps()
    ]
  end

  def elixirc_paths(:prod), do: ["lib"]
  def elixirc_paths(_), do: ["lib", "test/support"]

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      extra_applications: [:logger, :sweet_xml]
    ]
  end

  def package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE.md", "CONTRIBUTING.md"],
      maintainers: ["Ricardo Hermida Ruiz"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/locaweb/elixir-cassette",
        "Docs" => "https://hexdocs.pm/cassette/#{version()}"
      }
    ]
  end

  @elixir_version Version.parse!(System.version())
  @min_version_for_credo Version.parse!("1.7.0")

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:httpoison, "~> 0.8 or ~> 1.0"},
      {:sweet_xml, "~> 0.6.0"},
      {:ex_doc, "~> 0.11", only: :dev},
      {:earmark, "~> 1.0", only: :dev},
      {:bypass, "~> 1.0", only: [:dev, :test]},
      {:fake_cas, "~> 1.1", only: [:dev, :test]},
      {:excoveralls, "~> 0.7", only: :test}
    ]
    |> (fn deps ->
          if Version.compare(@elixir_version, @min_version_for_credo) in [:gt, :eq] do
            [{:credo, "~> 1.0", only: [:dev, :test], runtime: false} | deps]
          else
            deps
          end
        end).()
  end
end
