defmodule Blog.MixProject do
  use Mix.Project

  def project do
    [
      app: :blog,
      version: "1.0.0",
      elixir: "1.14.1",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :crypto]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:earmark, "~> 1.4"},
      {:esbuild, "~> 0.4", runtime: false},
      {:jason, "~> 1.2"},
      {:phoenix_view, "~> 2.0"},
      {:phoenix_html, "~> 3.2"},
      {:tailwind, "~> 0.1"},
      {:yaml_elixir, "~> 2.8"},
      {:xml_builder, "~> 2.1"}
    ]
  end
end
