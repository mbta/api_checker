ExUnit.start()

defmodule ApiChecker.TestHelpers do
  def datetime(string) do
    {:ok, dtg, _} = DateTime.from_iso8601(string)
    ApiChecker.PeriodicTask.Times.to_service_timezone(dtg)
  end
end
