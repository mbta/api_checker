defmodule ApiChecker.TripCountCacheTest do
  use ExUnit.Case, async: false
  alias ApiChecker.TripCountCache
  import ExUnit.CaptureLog

  setup do
    bypass = Bypass.open()
    Application.put_env(:api_checker, :trip_count_base_url, "http://localhost:#{bypass.port}")
    on_exit(fn -> Application.delete_env(:api_checker, :trip_count_base_url) end)
    %{bypass: bypass}
  end

  defp trip(id, route_id) do
    %{"id" => id, "relationships" => %{"route" => %{"data" => %{"id" => route_id}}}}
  end

  describe "get_count/2" do
    test "returns the number of trips from a response", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/trips", fn conn ->
        data = Enum.map(1..5, &trip("trip-#{&1}", "tc-single-page"))
        Plug.Conn.resp(conn, 200, Jason.encode!(%{"data" => data}))
      end)

      assert {:ok, 5} = TripCountCache.get_count(["tc-single-page"], 0)
    end

    test "excludes trips whose route relationship is not in the requested set", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/trips", fn conn ->
        data = [
          trip("t1", "tc-filter-route"),
          trip("t2", "tc-filter-route"),
          trip("shuttle-1", "tc-filter-shuttle"),
          trip("shuttle-2", "tc-filter-shuttle")
        ]
        Plug.Conn.resp(conn, 200, Jason.encode!(%{"data" => data}))
      end)

      assert {:ok, 2} = TripCountCache.get_count(["tc-filter-route"], 0)
    end

    test "excludes trips with no route relationship", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/trips", fn conn ->
        data = [
          trip("t1", "tc-no-rel-route"),
          %{"id" => "t2-no-rel"}
        ]
        Plug.Conn.resp(conn, 200, Jason.encode!(%{"data" => data}))
      end)

      assert {:ok, 1} = TripCountCache.get_count(["tc-no-rel-route"], 0)
    end

    test "caches the result within TTL", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/trips", fn conn ->
        Plug.Conn.resp(conn, 200, Jason.encode!(%{"data" => [trip("t1", "tc-cache-ttl")]}))
      end)

      # First call fetches; second call must use cache (Bypass raises if called twice with expect_once)
      assert {:ok, 1} = TripCountCache.get_count(["tc-cache-ttl"], 60)
      assert {:ok, 1} = TripCountCache.get_count(["tc-cache-ttl"], 60)
    end

    test "fetches fresh data after TTL expires", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/trips", fn conn ->
        Plug.Conn.resp(conn, 200, Jason.encode!(%{"data" => [trip("t1", "tc-ttl-expire")]}))
      end)

      assert {:ok, 1} = TripCountCache.get_count(["tc-ttl-expire"], 0)
      assert {:ok, 1} = TripCountCache.get_count(["tc-ttl-expire"], 0)
    end

    test "returns error and logs on non-200 status", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/trips", fn conn ->
        Plug.Conn.resp(conn, 500, "error")
      end)

      log =
        capture_log(fn ->
          assert {:error, {:unexpected_status, 500}} = TripCountCache.get_count(["tc-500-error"], 0)
        end)

      assert log =~ "TripCountCache fetch failed"
    end

    test "returns error on invalid JSON", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/trips", fn conn ->
        Plug.Conn.resp(conn, 200, "not json")
      end)

      log =
        capture_log(fn ->
          assert {:error, _} = TripCountCache.get_count(["tc-invalid-json"], 0)
        end)

      assert log =~ "TripCountCache fetch failed"
    end

    test "sorts routes so cache key is order-independent", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/trips", fn conn ->
        Plug.Conn.resp(conn, 200, Jason.encode!(%{"data" => [trip("t1", "tc-sort-a")]}))
      end)

      assert {:ok, 1} = TripCountCache.get_count(["tc-sort-b", "tc-sort-a"], 60)
      # Same routes in different order — should hit cache (Bypass raises if called twice)
      assert {:ok, 1} = TripCountCache.get_count(["tc-sort-a", "tc-sort-b"], 60)
    end
  end
end
