defmodule ApiChecker.Check.Params do
  @moduledoc """
  Defines an extensible struct that contains the parameters that can be passed
  along to a function that performs a "check".
  """

  defstruct raw_body: nil,
            decoded_body: nil,
            previous_response: nil,
            check_time: nil,
            name: nil
end
