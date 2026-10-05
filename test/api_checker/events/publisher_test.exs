defmodule ApiChecker.Events.PublisherTest do
  use ExUnit.Case
  doctest ApiChecker.Events.Publisher

  alias ApiChecker.Events.Publisher

  defmodule RecordingClient do
    @moduledoc false
    @behaviour ApiChecker.Events.KinesisClient

    @impl true
    def publish_event(stream_name, partition_key, data) do
      test_pid = Application.fetch_env!(:api_checker, :kinesis_test_pid)
      send(test_pid, {:publish_event, stream_name, partition_key, data})
      :ok
    end
  end

  setup do
    original_client = Application.get_env(:api_checker, :kinesis_client)
    original_stream_name = Application.get_env(:api_checker, :kinesis_stream_name)

    on_exit(fn ->
      Application.put_env(:api_checker, :kinesis_client, original_client)
      Application.put_env(:api_checker, :kinesis_stream_name, original_stream_name)
      Application.delete_env(:api_checker, :kinesis_test_pid)
    end)

    :ok
  end

  describe "publish/2" do
    test "sends a CloudEvent record to the configured Kinesis client when a stream name is configured" do
      Application.put_env(:api_checker, :kinesis_client, RecordingClient)
      Application.put_env(:api_checker, :kinesis_stream_name, "my-stream")
      Application.put_env(:api_checker, :kinesis_test_pid, self())

      assert Publisher.publish("heavy-rail-predictions-weekdays", true) == :ok

      assert_receive {:publish_event, "my-stream", "heavy-rail-predictions-weekdays", data}
      assert {:ok, decoded} = Jason.decode(data)
      assert decoded["data"] == %{"checkName" => "heavy-rail-predictions-weekdays", "success" => true}
      assert decoded["type"] == "com.mbta.api-checker.check.v1"
    end

    test "is a no-op when no stream name is configured" do
      Application.put_env(:api_checker, :kinesis_client, RecordingClient)
      Application.put_env(:api_checker, :kinesis_stream_name, nil)
      Application.put_env(:api_checker, :kinesis_test_pid, self())

      assert Publisher.publish("some-check", false) == :ok
      refute_receive {:publish_event, _, _, _}
    end

    test "is a no-op when the stream name is an empty string" do
      Application.put_env(:api_checker, :kinesis_client, RecordingClient)
      Application.put_env(:api_checker, :kinesis_stream_name, "")
      Application.put_env(:api_checker, :kinesis_test_pid, self())

      assert Publisher.publish("some-check", false) == :ok
      refute_receive {:publish_event, _, _, _}
    end
  end

  describe "success?/1" do
    test "returns true for :ok and {:ok, _} results" do
      assert Publisher.success?(:ok)
      assert Publisher.success?({:ok, length: 1})
    end

    test "returns false for {:error, _} and {:error, _, _} results" do
      refute Publisher.success?({:error, :stale_data})
      refute Publisher.success?({:error, :array_too_small, length: 0})
    end
  end
end
