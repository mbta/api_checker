defmodule ApiChecker.ScheduleCountCache do
  @moduledoc """
  A GenServer that caches the count of scheduled trips per route-set by querying the
  MBTA V3 API. Cache entries are invalidated after a configurable TTL (default: 60s).

  The MBTA V3 endpoint used is:
      GET /schedules?filter[route]=<routes>&filter[date]=<today>

  The count is the number of entries in the `data` array of the response that have a
  matching `relationships.route.data.id` (to exclude related routes like shuttles).
  """

  use GenServer
  require Logger

  @default_ttl_seconds 60 * 60
  @default_base_url "https://api-v3.mbta.com"

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Returns `{:ok, count}` for the number of schedules on the given routes today,
  using a cached value if one exists within `ttl_seconds`. Returns `{:error, reason}` on failure.
  """
  def get_count(routes, ttl_seconds \\ @default_ttl_seconds)
      when is_list(routes) and length(routes) > 0 do
    GenServer.call(__MODULE__, {:get_count, routes, ttl_seconds})
  end

  @impl GenServer
  def init(state) do
    {:ok, state}
  end

  @impl GenServer
  def handle_call({:get_count, routes, ttl_seconds}, _from, state) do
    key = cache_key(routes)
    now = System.os_time(:second)

    case Map.get(state, key) do
      {count, fetched_at} when now - fetched_at < ttl_seconds ->
        {:reply, {:ok, count}, state}

      _ ->
        case fetch_schedule_count(routes) do
          {:ok, count} ->
            {:reply, {:ok, count}, Map.put(state, key, {count, now})}

          {:error, reason} = err ->
            Logger.info(fn ->
              "ScheduleCountCache fetch failed routes=#{inspect(routes)} reason=#{inspect(reason)}"
            end)

            {:reply, err, state}
        end
    end
  end

  defp cache_key(routes) do
    routes |> Enum.sort() |> Enum.join(",")
  end

  defp fetch_schedule_count(routes) do
    base_url = Application.get_env(:api_checker, :schedule_count_base_url, @default_base_url)
    route_param = routes |> Enum.sort() |> Enum.join(",")
    date_param = Date.to_iso8601(Date.utc_today())

    url =
      "#{base_url}/schedules" <>
        "?filter[route]=#{URI.encode(route_param)}" <>
        "&filter[date]=#{date_param}"

    case HTTPoison.get(url, [], timeout: 10_000, recv_timeout: 10_000) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"data" => data}} when is_list(data) ->
            route_set = MapSet.new(routes)
            count = Enum.count(data, &schedule_on_route?(&1, route_set))
            {:ok, count}

          {:ok, _} ->
            {:error, :unexpected_response_shape}

          {:error, reason} ->
            {:error, {:json_decode_error, reason}}
        end

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        {:error, {:unexpected_status, status_code}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  defp schedule_on_route?(
         %{"relationships" => %{"route" => %{"data" => %{"id" => route_id}}}},
         route_set
       ) do
    MapSet.member?(route_set, route_id)
  end

  defp schedule_on_route?(_, _), do: false
end
