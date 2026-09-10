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

defmodule ArcGIS.Feature.Schema.Field do
  @moduledoc "A field in a table or layer schema."
  alias ArcGIS.Feature.Domain

  defstruct [
    :name,
    :label,
    :type,
    :type_label,
    domain: %Domain.None{},
    editable?: false,
    foreign_key?: false,
    primary_key?: false
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          label: String.t(),
          type: String.t(),
          type_label: String.t(),
          domain: Domain.t(),
          editable?: boolean,
          foreign_key?: boolean,
          primary_key?: boolean
        }
end
