defmodule ArcGIS.Feature.Domain.Enum do
  @moduledoc """
  An enumerated field. Enumerations are named and have a mapping of enumerated strings to actual values.
  """

  @enforce_keys [:name, :values]
  defstruct [:name, values: []]

  @type t :: %__MODULE__{
          name: String.t(),
          values: %{[label :: String.t()] => value :: String.t()}
        }
end
