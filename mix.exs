defmodule Rivet.Utils.MixProject do
  use Mix.Project

  def project do
    [
      app: :rivet_utils,
      version: "1.0.0",
      elixir: "~> 1.13",
      description: "Bespoke utilities for the Elixir Rivet Framework",
      source_url: "https://github.com/srevenant/rivet-utils",
      docs: [main: "Rivet.Utils"],
      package: package(),
      deps: deps(),
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.html": :test
      ],
      dialyzer: [
        # ignore_warnings: ".dialyzer_ignore.exs",
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [extra_applications: [:logger, :timex]]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:mix_test_watch, "~> 0.8", only: [:test, :dev], runtime: false},
      {:excoveralls, "~> 0.14", only: :test},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:transmogrify, "~> 1.1"},
      {:ecto, "~> 3.7"},
      {:jason, "~> 1.0"},
      {:timex, "~> 3.0"},
      {:csv, "~> 2.3"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false}
    ]
  end

  defp package() do
    [
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      licenses: ["AGPL-3.0-or-later"],
      links: %{"GitHub" => "https://github.com/srevenant/rivet-utils"},
      source_url: "https://github.com/srevenant/rivet-utils"
    ]
  end
end
