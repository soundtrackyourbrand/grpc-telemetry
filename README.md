# GRPCTelemetry

[![Build Status](https://travis-ci.org/soundtrackyourbrand/grpc-telemetry.svg?branch=master)](https://travis-ci.org/soundtrackyourbrand/grpc-telemetry)

Interceptor/middleware for gRPC that intruments requests with `:telemetry` events. Heavily inspired by [Plug.Telemetry](https://github.com/elixir-plug/plug/blob/master/lib/plug/telemetry.ex)

## Installation
Add as a dependency in your `mix.exs`:

```elixir
def deps do
  [
    {:grpc_telemetry, "1.0.0-rc.1"}
  ]
end
```

## Using
Add the interceptor as the first in your endpoint:

```elixir
defmodule MyApp.GRPC.Endpoint do
  use GRPC.Endpoint

  intercept(GRPCTelemetry, event_prefix: [:my_app, :grpc, :endpoint])

  run(MyApp.GRPC.Server)
end

```

You can now use the `:telemetry` events to export metrics, or trace
your gRPC requests.

## Telemetry.Metrics Example
Example usage with `Telemetry.Metrics`

```elixir
TelemetryMetricsPrometheus.child_spec(
  metrics: [
    counter("grpc.request.count",
      event_name: "my_app.grpc.endpoint.start",
      tags: [:service_name, :method_name]
    ),
    counter("grpc.response.count",
      event_name: "my_app.grpc.endpoint.stop",
      tags: [:service_name, :method_name, :status_code]
    ),
    distribution("grpc.response.duration",
      event_name: "my_app.grpc.endpoint.stop",
      tags: [:service_name, :method_name, :status_code],
      buckets: [0.1, 0.2, 0.4, 0.8, 1.6, 3.2, 6.4, 12.8, 25.6, 51.2],
      unit: {:native, :second}
    )
  ]
)
```
