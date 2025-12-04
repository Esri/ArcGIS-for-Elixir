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
