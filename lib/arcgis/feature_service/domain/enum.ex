defmodule ArcGIS.FeatureService.Domain.Enum do
  @enforce_keys [:name, :values]
  defstruct [:name, values: []]

  @type t :: %__MODULE__{
          name: String.t(),
          values: %{[label :: String.t()] => value :: String.t()}
        }
end
