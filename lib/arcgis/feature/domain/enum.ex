defmodule ArcGIS.Feature.Domain.Enum do
  @enforce_keys [:name, :values]
  defstruct [:name, values: []]

  @typedoc """
  An enumerated field. Enumerations are named and have a mapping of enumerated strings to actual values.
  """
  @type t :: %__MODULE__{
          name: String.t(),
          values: %{[label :: String.t()] => value :: String.t()}
        }
end
