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
