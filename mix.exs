defmodule Builder.MixProject do
  use Mix.Project

  def project do
    [
      app: :builder,
      version: "0.1.0",
      elixir: "1.10.4",
      start_permanent: Mix.env() == :production,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:earmark, "~> 1.4.10"},
      {:yaml_elixir, "~> 2.5.0"},
      {:traverse, "~> 1.0.1"},
      {:phoenix_html, "~> 2.14.2"},
      {:credo, "~> 1.5.0", only: [:dev], runtime: false},
      {:dialyxir, "~> 1.0.0", only: [:dev], runtime: false}
    ]
  end
end
