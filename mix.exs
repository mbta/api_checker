defmodule ApiChecker.Mixfile do
  use Mix.Project

  def project do
    [
      app: :api_checker,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.html": :test,
        "coveralls.json": :test
      ]
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
      {:timex, "~> 3.2"},
      {:httpoison, "~> 1.0"},
      {:credo, "~> 0.9.0-rc1", only: [:dev], runtime: false},
      {:excoveralls, "~> 0.8", only: :test},
      {:distillery, "~> 1.4", runtime: false, only: :prod}
    ]
  end
end
