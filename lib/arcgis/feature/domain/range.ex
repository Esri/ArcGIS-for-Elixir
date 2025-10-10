defmodule ArcGIS.Feature.Domain.Range do
  @enforce_keys [:name, :min, :max]
  defstruct [:name, :min, :max]

  @typedoc """
  A numerically constrained field. Ranges are named and have a minimum and maximum allowed value.
  """
  @type t :: %__MODULE__{
          name: String.t(),
          min: number,
          max: number
        }
end
