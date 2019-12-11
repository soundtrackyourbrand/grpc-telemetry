defmodule GRPCTelemetryTest do
  use ExUnit.Case
  doctest GRPCTelemetry

  test "greets the world" do
    assert GRPCTelemetry.hello() == :world
  end
end
