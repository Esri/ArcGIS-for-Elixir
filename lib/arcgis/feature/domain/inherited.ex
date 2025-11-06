defmodule ArcGIS.Feature.Domain.Inherited do
  @moduledoc """
  A field whose domain is inherited. The name is the actual domain to use for this field.
  """

  @enforce_keys [:name]
  defstruct [:name]

  @type t :: %__MODULE__{
          name: String.t()
        }
end
