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
end
