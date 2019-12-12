defmodule GRPCTelemetryTest.ServerAdapter do
  def read_body(_stream),
    do: {:ok, <<0, 0, 0, 0, 8>> <> :erlang.term_to_binary("body")}

  def get_headers(_stream) do
    %{"header" => "value"}
  end
end
