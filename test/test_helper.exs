ExUnit.start()

defmodule ApiChecker.TestHelpers do
  alias ApiChecker.PeriodicTask.Times

  def datetime(string) do
    {:ok, dtg, _} = DateTime.from_iso8601(string)
    Times.to_service_timezone(dtg)
  end
end
