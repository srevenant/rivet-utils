defmodule Rivet.Utils.MixProject do
  use Mix.Project

  def project do
    [
      app: :rivet_utils,
      version: "2.4.0",
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
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
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
      ]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:bcrypt_elixir, "~> 3.0"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ecto, "~> 3.13"},
      {:excoveralls, "~> 0.14", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:jason, "~> 1.0"},
      {:mix_test_watch, "~> 1.0", only: [:test, :dev], runtime: false},
      {:puid, "~> 2.0"},
      {:transmogrify, "~> 2.0.2"}
    ]
  end

  defp package() do
    [
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/srevenant/rivet-utils"},
      source_url: "https://github.com/srevenant/rivet-utils"
    ]
  end
end
