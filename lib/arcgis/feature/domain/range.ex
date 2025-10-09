defmodule ArcGIS.Feature.Domain.Range do
  @enforce_keys [:name, :min, :max]
  defstruct [:name, :min, :max]

  @type t :: %__MODULE__{
          name: String.t(),
          min: number,
          max: number
        }
end
