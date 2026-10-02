defmodule ApiChecker.Events.KinesisClientTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog

  alias ApiChecker.Events.KinesisClient.Noop

  describe "Noop.put_record/3" do
    test "doesn't raise and returns :ok without contacting AWS" do
      {result, captured} =
        with_log([level: :debug], fn ->
          Noop.put_record("some-stream", "partition-key", "{}")
        end)

      assert result == :ok

      assert captured =~ "Kinesis Noop"
      assert captured =~ ~s(stream_name="some-stream")
      assert captured =~ ~s(partition_key="partition-key")
    end
  end
end
