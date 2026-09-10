# Copyright 2026 Esri
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
