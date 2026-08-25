# Copyright 2025 Esri
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

 defmodule ArcGIS.Feature.Domain.Enum do
  @moduledoc """
  An enumerated field. Enumerations are named and have a mapping of enumerated strings to actual values.
  """

  @enforce_keys [:name, :values]
  defstruct [:name, values: []]

  @type t :: %__MODULE__{
          name: String.t(),
          values: %{[label :: String.t()] => value :: String.t()}
        }
end
