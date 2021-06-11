defmodule ApiChecker.Mixfile do
  use Mix.Project

  def project do
    [
      app: :api_checker,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: LcovEx]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ApiChecker.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.0"},
      {:tzdata, "~> 1.1"},
      {:httpoison, "~> 1.0"},
      {:hackney, "~> 1.17"},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:bypass, "~> 2.0", only: [:test]},
      {:lcov_ex, "~> 0.2", only: :test, runtime: false},
      {:distillery, "~> 2.0", only: :prod, runtime: false}
    ]
  end
end
