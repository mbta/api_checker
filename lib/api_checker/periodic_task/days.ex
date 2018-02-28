defmodule ApiChecker.PeriodicTask.Days do
  
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
    "SUN",
  ]

  def names do
    @names
  end
  
  def today_is do
    day = Date.day_of_week(Date.utc_today())
    index = day - 1
    Enum.at(@names, index)
  end
end