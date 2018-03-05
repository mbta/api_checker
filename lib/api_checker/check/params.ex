defmodule ApiChecker.Check.Params do
  @moduledoc """
  Defines an extensible struct that contains the parameters that can be passed
  along to a function that performs a "check".
  """

  defstruct raw_body: nil,
            decoded_body: nil
end
