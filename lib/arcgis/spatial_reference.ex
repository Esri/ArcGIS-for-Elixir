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

defmodule ArcGIS.SpatialReference do
  @moduledoc "An ArcGIS spatial reference"
  defstruct wkid: 0, alternatives: []

  @typedoc """
  A SpatialReference struct consists of a well-known ID and a list of
  equivalent IDs (if any).
  """
  @type t :: %{wkid: non_neg_integer, alternatives: [non_neg_integer]}

  @spec from_map(source :: map) :: t()
  @doc "Creates a `%ArcGIS.SpatialReference{}` from ArcGIS response data"
  def from_map(%{"latestWkid" => latest, "wkid" => wkid}) do
    %__MODULE__{wkid: latest, alternatives: [wkid]}
  end

  def from_map(%{"wkid" => wkid}) do
    %__MODULE__{wkid: wkid}
  end

  def from_map(_), do: %__MODULE__{}

  @spec best_srid(t()) :: non_neg_integer
  @doc "Given a spatial reference, return the 'best' spatial reference id to use."
  def best_srid(%{alternatives: [alt | _]}), do: alt
  def best_srid(%{wkid: wkid}), do: wkid
end
