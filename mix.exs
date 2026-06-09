defmodule ArcGIS.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :arcgis,
      name: "ArcGIS",
      version: @version,
      elixir: "~> 1.18",
      deps: deps(),
      docs: docs(),
      package: package(),
      preferred_cli_env: cli(),
      test_coverage: [tool: ExCoveralls],
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ArcGIS.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: elixirc_paths(:dev) ++ ["test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cachex, "~> 4.0"},
      {:inflex, "~> 2.0"},
      {:plug, "~> 1.0"},
      {:req, "~> 0.5"},
      {:telemetry, "~> 1.0"},
      {:geometry, "~> 1.0"},

      # dev depencencies
      {:mix_test_watch, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.14", only: :test, runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: [:dev, :test], runtime: false}
    ]
  end

  def cli do
    [
      preferred_envs: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.github": :test,
        "coveralls.html": :test,
        "test.watch": :test
      ]
    ]
  end

  defp package do
    [
      description: "Esri ArcGIS web services",
      maintainers: ["Aaron Seigo"],
      licenses: ["MIT"],
      links:
        %{
          #         "Changelog" => "https://hexdocs.pm/ical/changelog.html",
          #         "GitHub" => @source_url
        }
    ]
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme",
      source_ref: "v#{@version}",
      formatters: ["html"],
      groups_for_modules: [
        Users: [~r/ArcGIS.User.*/],
        Portals: [~r/ArcGIS.Portal.*/],
        Features: [~r/ArcGIS.Feature(?!.(Domain|Schema)).*/],
        Schemas: [~r/ArcGIS.Feature.Schema.*/],
        Domains: [~r/ArcGIS.Feature.Domain.*/],
        "Utility Types": [ArcGIS.Extent, ArcGIS.SpatialReference, ArcGIS.Timestamps]
      ]
    ]
  end
end
