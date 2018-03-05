defmodule ApiChecker.Check.JsonCheck.Vehicle do
  @moduledoc """
  The JSON check for a "vehicle".

  Example JSON:
  {
    "type": "vehicle",
    "relationships": {
      "trip": {
        "data": {
          "type": "trip",
          "id": "35448846-L"
        }
      },
      "stop": {
        "data": {
          "type": "stop",
          "id": "70061"
        }
      },
      "route": {
        "data": {
          "type": "route",
          "id": "Red"
        }
      }
    },
    "links": {
      "self": "/vehicles/5453FF2B"
    },
    "id": "5453FF2B",
    "attributes": {
      "speed": null,
      "longitude": -71.14054107666016,
      "latitude": 42.396209716796875,
      "last_updated": "2018-02-28T11:30:33-05:00",
      "label": "1626",
      "direction_id": 0,
      "current_stop_sequence": 1,
      "current_status": "STOPPED_AT",
      "bearing": 265
      }
    }
  """

  @doc """
  This function is not implemented.
  """
  def validate(_data) do
    {:error, :vehicle_json_check_is_not_implemented}
  end
end
