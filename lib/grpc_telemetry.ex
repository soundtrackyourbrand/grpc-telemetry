defmodule GRPCTelemetry do
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

      execute_stop(event_prefix, stream, start_time)

      rpc_return
    rescue
      e in GRPC.RPCError ->
        execute_stop(event_prefix, stream, start_time, e)
        reraise e, __STACKTRACE__
    end
  end

  defp execute_stop(event_prefix, stream, start_time, error \\ nil) do
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
