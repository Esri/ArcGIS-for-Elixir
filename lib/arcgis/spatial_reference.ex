defmodule ArcGIS.SpatialReference do
  defstruct wkid: 0, alternatives: []

  @typedoc """
  A struct representing a spatial references Consists of a well-known ID and a list of
  synonymous IDs (if any).
  """
  @type t :: %{wkid: non_neg_integer, alternatives: [non_neg_integer]}

  def from_map(%{"latestWkid" => latest, "wkid" => wkid}) do
    %__MODULE__{wkid: latest, alternatives: [wkid]}
  end

  def from_map(%{"wkid" => wkid}) do
    %__MODULE__{wkid: wkid}
  end

  def from_map(_), do: %__MODULE__{}
end
