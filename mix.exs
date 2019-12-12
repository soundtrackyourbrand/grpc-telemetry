defmodule GRPCTelemetry.MixProject do
  use Mix.Project

  @version "1.0.0-dev"
  @description "Telemetry interceptor/middleware for grpc"

  def project do
    [
      app: :grpc_telemetry,
      version: @version,
      description: @description,
      elixir: "~> 1.9",
      deps: deps(),
      package: package(),
      dialyzer: [
        plt_file: {:no_warn, "plts/dialyzer.plt"}
      ],
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    %{
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/soundtrackyourbrand/grpc-telemetry"}
    }
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:grpc, github: "elixir-grpc/grpc"},
      {:telemetry, "~> 0.4"},
      {:dialyxir, "~> 1.0.0-rc.7", only: [:dev], runtime: false}
    ]
  end
end
