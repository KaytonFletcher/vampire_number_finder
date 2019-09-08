defmodule Proj1.MixProject do
  use Mix.Project

  def project do
    [
      app: :proj1,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

end
