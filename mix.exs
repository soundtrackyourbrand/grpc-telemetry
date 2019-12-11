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
      package: package()
    ]
  end

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
      {:grpc, "~> 0.4", optional: true},
      {:telemetry, "~> 0.4", optional: true}
    ]
  end
end
