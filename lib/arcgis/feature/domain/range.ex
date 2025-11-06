defmodule ArcGIS.Feature.Domain.Range do
  @moduledoc """
  A numerically constrained field. Ranges are named and have a minimum and maximum allowed value.
  """

  @enforce_keys [:name, :min, :max]
  defstruct [:name, :min, :max]

  @type t :: %__MODULE__{
          name: String.t(),
          min: number,
          max: number
        }
end
