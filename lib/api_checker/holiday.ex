defmodule ApiChecker.Holiday do
  @moduledoc """
  Maintains a list of the current holidays.
  """
  use GenServer
  require Logger

  @api_url "https://api-v3.mbta.com/services/?filter[route]=Red,1&fields[service]=added_dates,added_dates_notes,removed_dates,removed_dates_notes"

  defstruct holidays: %{}

  def start_link(start_link_args \\ []) do
    GenServer.start_link(__MODULE__, [], start_link_args)
  end

  def is_holiday?(pid \\ __MODULE__, %Date{} = d) do
    GenServer.call(pid, {:is_holiday?, Date.to_iso8601(d)})
  end

  # Server functions
  def init(_) do
    {:ok, %__MODULE__{}}
  end

  def handle_call({:is_holiday?, iso_date}, _from, %{holidays: holidays} = state) when is_binary(iso_date) do
    state =
      if Map.has_key?(holidays, iso_date) do
        state
      else
        {:ok, new_holidays} = fetch_holidays()

        Logger.info(fn ->
          ["Found holidays: ", inspect(Map.keys(new_holidays))]
        end)

        new_holidays = Map.put_new(new_holidays, iso_date, false)
        %{state | holidays: Map.merge(holidays, new_holidays)}
      end

    {:reply, Map.get(state.holidays, iso_date, false), state}
  end

  def fetch_holidays do
    with {:ok, %{status_code: 200, body: body}} <- HTTPoison.get(@api_url),
         {:ok, json} <- Jason.decode(body),
         {:ok, data} <- Map.fetch(json, "data") do
      {:ok, parse_service_dates(data)}
    end
  end

  def parse_service_dates(data) do
    for %{"type" => "service"} = service <- data,
        attributes = Map.get(service, "attributes"),
        dates = Map.get(attributes, "added_dates", []) ++ Map.get(attributes, "removed_dates", []),
        notes = Map.get(attributes, "added_dates_notes", []) ++ Map.get(attributes, "removed_dates_notes", []),
        {iso_date, note} <- Enum.zip(dates, notes),
        not is_nil(note),
        into: %{} do
      {iso_date, true}
    end
  end
end
