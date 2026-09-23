defmodule ApiChecker.ScheduleCountCacheTest do
  use ExUnit.Case, async: false
  alias ApiChecker.ScheduleCountCache
  import ExUnit.CaptureLog
  doctest ScheduleCountCache

  setup do
    bypass = Bypass.open()
    Application.put_env(:api_checker, :schedule_count_base_url, "http://localhost:#{bypass.port}")
    on_exit(fn -> Application.delete_env(:api_checker, :schedule_count_base_url) end)
    %{bypass: bypass}
  end

  defp schedule(id, route_id) do
    %{"id" => id, "relationships" => %{"route" => %{"data" => %{"id" => route_id}}}}
  end

  describe "get_count/2" do
    test "sends min_time and max_time filters in the request", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/schedules", fn conn ->
        params = URI.decode_query(conn.query_string)
        assert Map.has_key?(params, "filter[min_time]")
        assert Map.has_key?(params, "filter[max_time]")
        assert Map.has_key?(params, "filter[date]")
        Plug.Conn.resp(conn, 200, Jason.encode!(%{"data" => []}))
      end)

      ScheduleCountCache.get_count(["sc-params-check"], 0)
    end

    test "returns the number of matching schedules from a response", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/schedules", fn conn ->
        data = Enum.map(1..5, &schedule("sched-#{&1}", "sc-single"))
        Plug.Conn.resp(conn, 200, Jason.encode!(%{"data" => data}))
      end)

      assert {:ok, 5} = ScheduleCountCache.get_count(["sc-single"], 0)
    end

    test "excludes schedules whose route relationship is not in the requested set", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/schedules", fn conn ->
        data = [
          schedule("s1", "sc-filter-route"),
          schedule("s2", "sc-filter-route"),
          schedule("shuttle-1", "sc-filter-shuttle"),
          schedule("shuttle-2", "sc-filter-shuttle")
        ]

        Plug.Conn.resp(conn, 200, Jason.encode!(%{"data" => data}))
      end)

      assert {:ok, 2} = ScheduleCountCache.get_count(["sc-filter-route"], 0)
    end

    test "excludes schedules with no route relationship", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/schedules", fn conn ->
        data = [schedule("s1", "sc-no-rel-route"), %{"id" => "s2-no-rel"}]
        Plug.Conn.resp(conn, 200, Jason.encode!(%{"data" => data}))
      end)

      assert {:ok, 1} = ScheduleCountCache.get_count(["sc-no-rel-route"], 0)
    end

    test "caches the result within TTL", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/schedules", fn conn ->
        Plug.Conn.resp(conn, 200, Jason.encode!(%{"data" => [schedule("s1", "sc-cache-ttl")]}))
      end)

      assert {:ok, 1} = ScheduleCountCache.get_count(["sc-cache-ttl"], 60)
      assert {:ok, 1} = ScheduleCountCache.get_count(["sc-cache-ttl"], 60)
    end

    test "fetches fresh data after TTL expires", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/schedules", fn conn ->
        Plug.Conn.resp(conn, 200, Jason.encode!(%{"data" => [schedule("s1", "sc-ttl-expire")]}))
      end)

      assert {:ok, 1} = ScheduleCountCache.get_count(["sc-ttl-expire"], 0)
      assert {:ok, 1} = ScheduleCountCache.get_count(["sc-ttl-expire"], 0)
    end

    test "returns error and logs on non-200 status", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/schedules", fn conn ->
        Plug.Conn.resp(conn, 500, "error")
      end)

      log =
        capture_log(fn ->
          assert {:error, {:unexpected_status, 500}} =
                   ScheduleCountCache.get_count(["sc-500-error"], 0)
        end)

      assert log =~ "ScheduleCountCache fetch failed"
    end

    test "returns error on invalid JSON", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/schedules", fn conn ->
        Plug.Conn.resp(conn, 200, "not json")
      end)

      log =
        capture_log(fn ->
          assert {:error, _} = ScheduleCountCache.get_count(["sc-invalid-json"], 0)
        end)

      assert log =~ "ScheduleCountCache fetch failed"
    end

    test "sorts routes so cache key is order-independent", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/schedules", fn conn ->
        Plug.Conn.resp(conn, 200, Jason.encode!(%{"data" => [schedule("s1", "sc-sort-a")]}))
      end)

      assert {:ok, 1} = ScheduleCountCache.get_count(["sc-sort-b", "sc-sort-a"], 60)
      assert {:ok, 1} = ScheduleCountCache.get_count(["sc-sort-a", "sc-sort-b"], 60)
    end
  end
end
