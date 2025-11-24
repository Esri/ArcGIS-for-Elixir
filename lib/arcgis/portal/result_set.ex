defmodule ArcGIS.Portal.ResultSet do
  @moduledoc """
  A struct representing a paged set of results from an ArcGIS Portal query.

  This is used with both portal item queries as well as feature queries,
  normalizing the way different types of queries return paging information.
  """

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
