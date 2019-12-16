defmodule GRPCTelemetryTest.Interceptors do
  defmodule RaiseError do
    def init(opts), do: opts
    def call(_, _, _, _), do: raise(GRPC.RPCError.new(:internal))
  end

  defmodule ReturnError do
    def init(opts), do: opts
    def call(_, _, _, _), do: {:error, GRPC.RPCError.new(:internal)}
  end
end
