defmodule ArcGIS.MixProject do
  use Mix.Project

  def project do
    [
      app: :arcgis,
      name: "ArcGIS",
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: &docs/0,
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
      {:telemetry, "~> 1.0"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false, warn_if_outdated: true},
      {:mix_test_watch, "~> 1.0", only: [:test]}
    ]
  end

  defp docs do
    [
      main: "ArcGIS",
      extras: ["README.md"]
    ]
  end
end
