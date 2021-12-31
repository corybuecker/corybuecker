defmodule Blog.MixProject do
  use Mix.Project

  def project do
    [
      app: :blog,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:earmark, "~> 1.4"},
      {:esbuild, "~> 0.4.0", runtime: false},
      {:jason, "~> 1.2"},
      {:phoenix_live_view, "~> 0.17.5"},
      {:phoenix_view, "~> 1.0"},
      {:tailwind, "~> 0.1.2",
       runtime: false,
       git: "https://github.com/bowmanmike/tailwind.git",
       branch: "add-linux-arm64-target"},
      {:yaml_elixir, "~> 2.8"}
    ]
  end
end
