defmodule GRPCTelemetryTest do
  use ExUnit.Case
  doctest GRPCTelemetry

  defmodule Server do
    use GRPC.Server, service: Helloworld.Greeter.Service

    def say_hello(_req, _stream), do: "response"
  end

  defmodule Endpoint do
    use GRPC.Endpoint

    intercept(GRPCTelemetry, event_prefix: [:my, :prefix])

    run(Server)
  end

  defmodule EndpointRaiseError do
    use GRPC.Endpoint

    intercept(GRPCTelemetry, event_prefix: [:my, :prefix])
    intercept(GRPCTelemetryTest.Interceptors.RaiseError)

    run(Server)
  end

  defmodule EndpointReturnError do
    use GRPC.Endpoint

    intercept(GRPCTelemetry, event_prefix: [:my, :prefix])
    intercept(GRPCTelemetryTest.Interceptors.ReturnError)

    run(Server)
  end

  setup do
    start_handler_id = {:start, :rand.uniform(100)}
    stop_handler_id = {:stop, :rand.uniform(100)}

    on_exit(fn ->
      :telemetry.detach(start_handler_id)
      :telemetry.detach(stop_handler_id)
    end)

    {:ok, start_handler: start_handler_id, stop_handler: stop_handler_id}
  end

  test "emits stop and start events with prefix", %{
    start_handler: start_handler,
    stop_handler: stop_handler
  } do
    attach(start_handler, [:my, :prefix, :start])
    attach(stop_handler, [:my, :prefix, :stop])

    stream = %GRPC.Server.Stream{
      endpoint: Endpoint,
      server: Server,
      adapter: GRPCTelemetryTest.ServerAdapter
    }

    assert {:ok, %GRPC.Server.Stream{}, "response"} =
             Server.__call_rpc__("/helloworld.Greeter/SayHello", stream)

    assert_received {:event, [:my, :prefix, :start], measurements, metadata}
    assert map_size(measurements) == 1
    assert %{time: time} = measurements
    assert is_integer(time)
    assert %{method_name: "SayHello"} = metadata
    assert %{service_name: "helloworld.Greeter"} = metadata
    assert %{headers: %{"header" => "value"}} = metadata

    assert_received {:event, [:my, :prefix, :stop], measurements, metadata}
    assert map_size(measurements) == 1
    assert %{duration: duration} = measurements
    assert is_integer(duration)
    assert %{method_name: "SayHello"} = metadata
    assert %{service_name: "helloworld.Greeter"} = metadata
    assert %{headers: %{"header" => "value"}} = metadata
    assert %{status_code: 0} = metadata
    assert %{status_message: "OK"} = metadata
  end

  test "emits correct status and message on raised error", %{
    start_handler: start_handler,
    stop_handler: stop_handler
  } do
    attach(start_handler, [:my, :prefix, :start])
    attach(stop_handler, [:my, :prefix, :stop])

    stream = %GRPC.Server.Stream{
      endpoint: EndpointRaiseError,
      server: Server,
      adapter: GRPCTelemetryTest.ServerAdapter
    }

    assert_raise(GRPC.RPCError, fn ->
      Server.__call_rpc__("/helloworld.Greeter/SayHello", stream)
    end)

    assert_received {:event, [:my, :prefix, :start], measurements, metadata}
    assert map_size(measurements) == 1

    assert_received {:event, [:my, :prefix, :stop], measurements, metadata}
    assert map_size(measurements) == 1
    assert %{status_code: 13} = metadata
    assert %{status_message: "Internal errors"} = metadata
  end

  test "emits correct status and message on return error", %{
    start_handler: start_handler,
    stop_handler: stop_handler
  } do
    attach(start_handler, [:my, :prefix, :start])
    attach(stop_handler, [:my, :prefix, :stop])

    stream = %GRPC.Server.Stream{
      endpoint: EndpointReturnError,
      server: Server,
      adapter: GRPCTelemetryTest.ServerAdapter
    }

    assert {:error, _} = Server.__call_rpc__("/helloworld.Greeter/SayHello", stream)

    assert_received {:event, [:my, :prefix, :start], measurements, metadata}
    assert map_size(measurements) == 1

    assert_received {:event, [:my, :prefix, :stop], measurements, metadata}
    assert map_size(measurements) == 1
    assert %{status_code: 13} = metadata
    assert %{status_message: "Internal errors"} = metadata
  end

  defp attach(handler_id, event) do
    :telemetry.attach(
      handler_id,
      event,
      fn event, measurements, metadata, _ ->
        send(self(), {:event, event, measurements, metadata})
      end,
      nil
    )
  end
end
