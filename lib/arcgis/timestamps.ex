defmodule ArcGIS.Timestamps do
  @moduledoc "Creation, modification, last access timestamps for an object"

  # not included:
  #  * autoJoin
  #  *
  defstruct [:created, :last_access, :modified]

  @type timestamp :: non_neg_integer | nil
  @type t :: %__MODULE__{
          created: timestamp,
          last_access: timestamp,
          modified: timestamp
        }
end
