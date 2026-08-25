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

defmodule ArcGIS.Feature.Domain do
  @moduledoc """
  Data constraints and definitions applicable to a field in a feature service table or layer.
  One of a `t:ArcGIS.Feature.Domain.Enum.t/0`,  `t:ArcGIS.Feature.Domain.Range.t/0`,
  `t:ArcGIS.Feature.Domain.Inherited.t/0`, or (the default)  `t:ArcGIS.Feature.Domain.None.t/0`
  """
  @type t ::
          __MODULE__.Enum.t()
          | __MODULE__.Range.t()
          | __MODULE__.Inherited.t()
          | __MODULE__.None.t()
end
