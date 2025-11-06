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
