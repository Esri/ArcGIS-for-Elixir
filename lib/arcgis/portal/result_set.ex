defmodule ArcGIS.Portal.ResultSet do
  defstruct offset: 0,
            next_offset: 0,
            more?: false,
            results: [],
            spatialReference: %ArcGIS.SpatialReference{}

  @type t :: %__MODULE__{
          offset: non_neg_integer,
          next_offset: non_neg_integer,
          results: list,
          more?: boolean,
          spatialReference: ArcGIS.SpatialReference.t()
        }
end
