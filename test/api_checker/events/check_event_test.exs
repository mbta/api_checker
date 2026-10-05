defmodule ApiChecker.Events.CheckEventTest do
  use ExUnit.Case, async: false
  doctest ApiChecker.Events.CheckEvent

  alias ApiChecker.Events.CheckEvent

  describe "build/3" do
    test "builds a CloudEvent map matching the com.mbta.api-checker.check schema" do
      previous_kinesis_source = Application.get_env(:api_checker, :kinesis_stream_source)

      on_exit(fn ->
        if previous_kinesis_source,
          do: Application.put_env(:api_checker, :kinesis_stream_source, previous_kinesis_source),
          else: Application.delete_env(:api_checker, :kinesis_stream_source)
      end)

      Application.put_env(:api_checker, :kinesis_stream_source, "api-checker-fake-source")

      now = ~U[2026-09-24 12:01:00.110000Z]
      event = CheckEvent.build("heavy-rail-predictions-weekdays", true, now)

      assert event == %{
               data: %{checkName: "heavy-rail-predictions-weekdays", success: true},
               id: event.id,
               source: "api-checker-fake-source",
               specversion: "1.0",
               time: "2026-09-24T12:01:00.110000Z",
               type: "com.mbta.api-checker.check.v1"
             }
    end

    test "reflects a failing check's success value" do
      event = CheckEvent.build("some-check", false)
      assert event.data.success == false
    end

    test "generates a unique, well-formed id for each event" do
      event_1 = CheckEvent.build("some-check", true)
      event_2 = CheckEvent.build("some-check", true)

      assert event_1.id != event_2.id
      assert event_1.id =~ ~r/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/
    end

    test "defaults `now` to the current time" do
      before = DateTime.utc_now()
      event = CheckEvent.build("some-check", true)
      after_ = DateTime.utc_now()

      {:ok, event_time, 0} = DateTime.from_iso8601(event.time)
      assert DateTime.compare(event_time, before) in [:gt, :eq]
      assert DateTime.compare(event_time, after_) in [:lt, :eq]
    end
  end

  describe "encode/1" do
    test "encodes a built event as JSON" do
      now = ~U[2026-09-24 12:01:00.110000Z]
      event = CheckEvent.build("heavy-rail-predictions-weekdays", true, now)
      json = CheckEvent.encode(event)

      assert {:ok, decoded} = Jason.decode(json)

      assert decoded == %{
               "data" => %{"checkName" => "heavy-rail-predictions-weekdays", "success" => true},
               "id" => event.id,
               "source" => "api-checker",
               "specversion" => "1.0",
               "time" => "2026-09-24T12:01:00.110000Z",
               "type" => "com.mbta.api-checker.check.v1"
             }
    end
  end
end
