defmodule ArcGIS.Portal.HelperService do
  @moduledoc """
  ArcGIS portals host several additional helper services, each with their own
  URL endpoints and APIs. This module contains the information needed to utilize
  such a helper service.

  Each helper service has at least one published URL and optional additonal parameters
  that are implementation-specific to the helper service. Some services may have multiple
  endpoints, and if they do those endpoints (and their parameters, if any) are stored under
  the `auxiliary` key.

  Services may be discovered for a portal by by calling `ArcGIS.Portal.discover/1`.
  """

  @enforce_keys [:url]
  defstruct [:url, parameters: %{}, auxiliary: []]

  @type t :: %{
          url: URI.t(),
          parameters: %{String.t() => String.t()},
          auxiliary: [
            %{
              url: URI.t(),
              parameters: %{String.t() => String.t()}
            }
          ]
        }
end
