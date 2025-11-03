defmodule ArcGIS.User.Role do
  @moduledoc "A user role"
  defstruct [:id, :name]

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t()
        }

  @spec new(map) :: t()
  @doc "Creates a Role struct given a map of user data"
  def new(%{} = user) do
    %__MODULE__{
      id: Map.get(user, "roleId", ""),
      name: Map.get(user, "role", "")
    }
  end
end
