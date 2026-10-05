defmodule ApiChecker.Events.PublisherServerTest do
  use ExUnit.Case

  alias ApiChecker.Events.PublisherServer

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

    Application.put_env(:api_checker, :kinesis_client, RecordingClient)
    Application.put_env(:api_checker, :kinesis_stream_name, "my-stream")
    Application.put_env(:api_checker, :kinesis_test_pid, self())

    on_exit(fn ->
      Application.put_env(:api_checker, :kinesis_client, original_client)
      Application.put_env(:api_checker, :kinesis_stream_name, original_stream_name)
      Application.delete_env(:api_checker, :kinesis_test_pid)
    end)

    {:ok, pid} = GenServer.start_link(PublisherServer, nil)
    %{server: pid}
  end

  test "asynchronously publishes a check event to the configured Kinesis client", %{server: server} do
    assert PublisherServer.publish("heavy-rail-predictions-weekdays", true, server) == :ok

    assert_receive {:publish_event, "my-stream", "heavy-rail-predictions-weekdays", data}
    assert {:ok, decoded} = Jason.decode(data)
    assert decoded["data"] == %{"checkName" => "heavy-rail-predictions-weekdays", "success" => true}
  end

  test "does not block the caller while the Kinesis publish happens", %{server: server} do
    assert PublisherServer.publish("some-check", false, server) == :ok
    assert_receive {:publish_event, "my-stream", "some-check", _data}
  end
end
