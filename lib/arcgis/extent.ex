defmodule ArcGIS.Extent do
  defstruct northwest: %Geometry.Point{}, southeast: %Geometry.Point{}

  @type t :: %__MODULE__{northwest: Geometry.Point.t(), southeast: %Geometry.Point{}}

  def new([nw, se]) do
    %__MODULE__{
      northwest: Geometry.Point.new(nw),
      southeast: Geometry.Point.new(se)
    }
  end

  def new(_), do: %__MODULE__{}
end
