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

 defmodule ArcGIS.Portal.ResultSet do
  @moduledoc """
  A struct representing a paged set of results from an ArcGIS Portal query.

  This is used with both portal item queries as well as feature queries,
  normalizing the way different types of queries return paging information.
  """

  defstruct offset: 0,
            next_offset: 0,
            more?: false,
            results: [],
            spatial_reference: %ArcGIS.SpatialReference{}

  @type t :: %__MODULE__{
          offset: non_neg_integer,
          next_offset: non_neg_integer,
          results: list,
          more?: boolean,
          spatial_reference: ArcGIS.SpatialReference.t()
        }
end
