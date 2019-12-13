defmodule GRPCTelemetry.MixProject do
  use Mix.Project

  @version "1.0.0-rc.1"
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
      elixirc_paths: elixirc_paths(Mix.env()),
      docs: [
        extras: [
          "README.md"
        ],
        main: "readme",
        source_ref: "v#{@version}",
        source_url: "https://github.com/soundtrackyourbrand/grpc-telemetry"
      ]
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
      {:grpc, "~> 0.4.0-alpha.2"},
      {:telemetry, "~> 0.4"},
      {:dialyxir, "~> 1.0.0-rc.7", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.21", only: :dev}
    ]
  end
end
