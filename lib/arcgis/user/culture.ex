defmodule ArcGIS.User.Culture do
  @moduledoc "Cultural settings information"
  defstruct [:code, :format, :units]

  @type t :: %__MODULE__{
          code: String.t(),
          format: String.t(),
          units: String.t()
        }

  @spec new(map) :: t()
  @doc "Creates a Culture struct given a map of user data"
  def new(%{} = user) do
    # TODO: better defaults than ""
    %__MODULE__{
      code: Map.get(user, "culture", ""),
      format: Map.get(user, "cultureFormat", ""),
      units: Map.get(user, "units", "")
    }
  end
end
