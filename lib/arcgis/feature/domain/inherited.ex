defmodule ArcGIS.Feature.Domain.Inherited do
  @enforce_keys [:name]
  defstruct [:name]

  @typedoc """
  A field whose domain is inherited. The name is the actual domain to use for this field.
  """
  @type t :: %__MODULE__{
          name: String.t()
        }
end
