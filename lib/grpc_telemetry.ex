defmodule GRPCTelemetry do
  @moduledoc """
  An interceptor for instrumenting gRPC requests with `:telemetry` events.

  GRPCTelemetry takes one option, the event prefix:

      intercept(GRPCTelemetry, event_prefix: [:my, :endpoint])

  It will emit two events:

      * `[:my, :endpoint, :start]` is emitted the interceptor
      is called, it contains the monotonic time in native units
      when the event was emitted, called `time`.

      * `[:my, :endpoint, :stop]` is emitted after the rest
      of the interceptor chain has executed, and will contains
      `duration`, the monotonic time difference between the stop
      and start event, in native units.

  GRPCTelemetry should be added as the first interceptor, so that it
  instruments the whole request.
  """

  @spec init(event_prefix: [atom]) :: [atom]
  def init(opts) do
    event_prefix = Keyword.get(opts, :event_prefix)

    unless event_prefix do
      raise ArgumentError, ":event_prefix is required"
    end

    event_prefix
  end

  @spec call(GRPC.Server.rpc_req(), GRPC.Server.Stream.t(), GRPC.ServerInterceptor.next(), any) ::
          GRPC.ServerInterceptor.rpc_return()
  def call(req, stream, next, event_prefix) do
    start_time = System.monotonic_time()

    :telemetry.execute(start_event(event_prefix), %{time: start_time}, %{
      headers: GRPC.Stream.get_headers(stream),
      method_name: stream.method_name,
      service_name: stream.service_name
    })

    try do
      rpc_return = next.(req, stream)

      err =
        case rpc_return do
          {:error, %GRPC.RPCError{} = rpc_error} -> rpc_error
          _ -> nil
        end

      execute_stop(event_prefix, stream, start_time, err)

      rpc_return
    rescue
      e in GRPC.RPCError ->
        execute_stop(event_prefix, stream, start_time, e)
        reraise e, __STACKTRACE__
    end
  end

  defp execute_stop(event_prefix, stream, start_time, error) do
    {status_code, status_message} =
      case error do
        %GRPC.RPCError{status: s, message: m} -> {s, m}
        nil -> {GRPC.Status.ok(), "OK"}
      end

    duration = System.monotonic_time() - start_time

    :telemetry.execute(stop_event(event_prefix), %{duration: duration}, %{
      headers: GRPC.Stream.get_headers(stream),
      method_name: stream.method_name,
      service_name: stream.service_name,
      status_code: status_code,
      status_message: status_message
    })
  end

  defp start_event(prefix), do: prefix ++ [:start]
  defp stop_event(prefix), do: prefix ++ [:stop]
end
