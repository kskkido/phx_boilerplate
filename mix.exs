defmodule PhxBoilerplate.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :phx_boilerplate,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
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
      {:phx_new, "~> 1.8", only: :dev, runtime: false},
    ]
  end

  defp aliases do
    [
      build: ["archive.build --include-dot-files"],
      install: ["archive.install phx_boilerplate-#{@version}.ez"]
    ]
  end
end
