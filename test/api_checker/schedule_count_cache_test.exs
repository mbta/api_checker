defmodule ApiChecker.ScheduleCountCacheTest do
  use ExUnit.Case, async: false
  alias ApiChecker.ScheduleCountCache
  import ExUnit.CaptureLog

  setup do
    bypass = Bypass.open()
    Application.put_env(:api_checker, :schedule_count_base_url, "http://localhost:#{bypass.port}")
    on_exit(fn -> Application.delete_env(:api_checker, :schedule_count_base_url) end)
    %{bypass: bypass}
  end

  defp trip(id, route_id) do
    %{"id" => id, "relationships" => %{"route" => %{"data" => %{"id" => route_id}}}}
  end

  describe "get_count/2" do
    test "returns the number of trips from a response", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/schedules", fn conn ->
        data = Enum.map(1..5, &trip("trip-#{&1}", "sc-single-page"))
        Plug.Conn.resp(conn, 200, Jason.encode!(%{"data" => data}))
      end)

      assert {:ok, 5} = ScheduleCountCache.get_count(["sc-single-page"], 0)
    end

    test "excludes trips whose route relationship is not in the requested set", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/schedules", fn conn ->
        data = [
          trip("t1", "sc-filter-route"),
          trip("t2", "sc-filter-route"),
          trip("shuttle-1", "sc-filter-shuttle"),
          trip("shuttle-2", "sc-filter-shuttle")
        ]
        Plug.Conn.resp(conn, 200, Jason.encode!(%{"data" => data}))
      end)

      assert {:ok, 2} = ScheduleCountCache.get_count(["sc-filter-route"], 0)
    end

    test "excludes trips with no route relationship", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/schedules", fn conn ->
        data = [
          trip("t1", "sc-no-rel-route"),
          %{"id" => "t2-no-rel"}
        ]
        Plug.Conn.resp(conn, 200, Jason.encode!(%{"data" => data}))
      end)

      assert {:ok, 1} = ScheduleCountCache.get_count(["sc-no-rel-route"], 0)
    end

    test "caches the result within TTL", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/schedules", fn conn ->
        Plug.Conn.resp(conn, 200, Jason.encode!(%{"data" => [trip("t1", "sc-cache-ttl")]}))
      end)

      # First call fetches; second call must use cache (Bypass raises if called twice with expect_once)
      assert {:ok, 1} = ScheduleCountCache.get_count(["sc-cache-ttl"], 60)
      assert {:ok, 1} = ScheduleCountCache.get_count(["sc-cache-ttl"], 60)
    end

    test "fetches fresh data after TTL expires", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/schedules", fn conn ->
        Plug.Conn.resp(conn, 200, Jason.encode!(%{"data" => [trip("t1", "sc-ttl-expire")]}))
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
          assert {:error, {:unexpected_status, 500}} = ScheduleCountCache.get_count(["sc-500-error"], 0)
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
        Plug.Conn.resp(conn, 200, Jason.encode!(%{"data" => [trip("t1", "sc-sort-a")]}))
      end)

      assert {:ok, 1} = ScheduleCountCache.get_count(["sc-sort-b", "sc-sort-a"], 60)
      # Same routes in different order — should hit cache (Bypass raises if called twice)
      assert {:ok, 1} = ScheduleCountCache.get_count(["sc-sort-a", "sc-sort-b"], 60)
    end
  end
end
