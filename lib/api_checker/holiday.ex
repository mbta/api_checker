defmodule ApiChecker.Holiday do
  @moduledoc """
  Maintains a list of the current holidays.
  """
  use GenServer

  defstruct holidays: %{}

  def start_link(start_link_args \\ []) do
    GenServer.start_link(__MODULE__, [], start_link_args)
  end

  def is_holiday?(pid \\ __MODULE__, %Date{} = d) do
    GenServer.call(pid, {:is_holiday?, d})
  end

  # Server functions
  def init(_) do
    {:ok, %__MODULE__{}}
  end

  def handle_call({:is_holiday?, d}, _from, %{holidays: holidays} = state) do
    {state, is_holiday?} =
      case Map.fetch(holidays, d) do
        {:ok, is_holiday?} ->
          {state, is_holiday?}

        :error ->
          {:ok, is_holiday?} = is_holiday_api(d)
          {put_in(state.holidays[d], is_holiday?), is_holiday?}
      end

    {:reply, is_holiday?, state}
  end

  defp is_holiday_api(d) do
    iso_date = Date.to_iso8601(d)

    with {:ok, %{status_code: 200, body: body}} <- HTTPoison.get(is_holiday_api_url(iso_date)),
         {:ok, json} <- Jason.decode(body) do
      [%{"attributes" => service} | _] = json["included"]
      dates = service["added_dates"] ++ service["removed_dates"]
      notes = service["added_dates_notes"] ++ service["removed_dates_notes"]
      combined = Enum.zip(dates, notes)

      case Enum.find(combined, &(elem(&1, 0) == iso_date)) do
        {^iso_date, nil} ->
          {:ok, false}

        {^iso_date, _} ->
          {:ok, true}

        nil ->
          {:ok, false}
      end
    end
  end

  defp is_holiday_api_url(iso_date) do
    "https://api-v3.mbta.com/trips/?filter[route]=Red&filter[date]=#{iso_date}&include=service&page[limit]=1&fields[trip]=&fields[service]=added_dates,added_dates_notes,removed_dates,removed_dates_notes"
  end
end
