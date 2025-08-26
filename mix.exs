defmodule ArcGIS.MixProject do
  use Mix.Project

  def project do
    [
      app: :arcgis,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      preferred_envs: [test_watch: :test]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ArcGIS.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cachex, "~> 4.0"},
      {:req, "~> 0.5"},
      {:mix_test_watch, "~> 1.0", only: [:dev, :test]}
    ]
  end
end
