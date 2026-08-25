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

defmodule ArcGIS.Extent do
  @moduledoc """
  A struct representing a simple box-shaped extent with a norwest and southeast point.
  """

  defstruct northwest: %Geometry.Point{}, southeast: %Geometry.Point{}

  @type t :: %__MODULE__{northwest: Geometry.Point.t(), southeast: %Geometry.Point{}}

  @spec new([[number]]) :: t()
  @doc """
  Creates an `%ArcGIS.Extent{}` struct from an array as typically returned by ArcGIS.

  It expects two elements in the an array, each containing two coordinates, 
  such as `[[north, west], [south, east]]`. Otherwise, it will return an empty extent.
  """
  def new([nw, se]) do
    %__MODULE__{
      northwest: Geometry.Point.new(nw),
      southeast: Geometry.Point.new(se)
    }
  end

  def new(_), do: %__MODULE__{}

  def empty?(%__MODULE__{} = extent) do
    extent.northwest.coordinates === []
  end
end
