defmodule ApiChecker.HolidayTest do
  @moduledoc false
  use ExUnit.Case, async: true
  import ApiChecker.Holiday

  @holiday_date ~D[2021-02-15]
  @regular_date ~D[2021-03-24]

  @api_data %{
    data: [
      %{
        id: "test_service",
        type: "service",
        attributes: %{
          added_dates: [@regular_date],
          added_dates_notes: [nil],
          removed_dates: [@holiday_date],
          removed_dates_notes: ["Holiday"],
          start_date: @holiday_date,
          end_date: @regular_date,
          valid_days: []
        }
      }
    ]
  }

  setup do
    Application.ensure_all_started(:bypass)
    bypass = Bypass.open()

    Bypass.stub(bypass, "GET", "/", fn conn ->
      Plug.Conn.send_resp(conn, 200, Jason.encode_to_iodata!(@api_data))
    end)

    {:ok, pid} = start_link(api_url: "http://127.0.0.1:#{bypass.port}/")
    {:ok, %{pid: pid}}
  end

  describe "is_holiday?/1" do
    test "returns true for holidays", %{pid: pid} do
      assert is_holiday?(pid, @holiday_date)
    end

    test "returns false for non holidays", %{pid: pid} do
      refute is_holiday?(pid, @regular_date)
    end
  end
end
