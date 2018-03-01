defmodule ApiChecker.PeriodicTask.Days do
  alias ApiChecker.PeriodicTask.Times
  # The order matters.
  # Monday comes first.
  # Sunday comes last.
  @names [
    "MON",
    "TUE",
    "WED",
    "THU",
    "FRI",
    "SAT",
    "SUN"
  ]

  def names do
    @names
  end

  def today_is do
    name_of_day(Date.utc_today())
  end

  def name_of_day(%DateTime{} = datetime) do
    datetime
    |> Times.to_service_timezone()
    |> DateTime.to_date()
    |> name_of_day
  end

  def name_of_day(%Date{} = date) do
    day = Date.day_of_week(date)
    index = day - 1
    Enum.at(@names, index)
  end

  @doc """
  Returns true for capitalized three-lettered abbreviations for days of the week.
  Returns false for anything else.

  iex> Days.is_day_of_week?("FRI")
  true

  iex> Days.is_day_of_week?("fri")
  false

  iex> Days.is_day_of_week?("DAY")
  false
  """
  def is_day_of_week?(day) do
    day in @names
  end
end
