defmodule ArcGIS.Features.Domain.Inherited do
  @enforce_keys [:name]
  defstruct [:name]

  @type t :: %__MODULE__{
          name: String.t()
        }
end
