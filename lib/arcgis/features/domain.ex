defmodule ArcGIS.Features.Domain do
  @type t ::
          __MODULE__.Enum.t()
          | __MODULE__.Range.t()
          | __MODULE__.Inherited.t()
          | __MODULE__.None.t()
end
