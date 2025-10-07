defmodule ArcGIS do
  @moduledoc """
  Support for ArcGIS Online and ArcGIS Enterprise web APIs.

  Currently supported:

    * Simple user authentication
    * Portal API access
    * Feature services:
      * Querying and mutating features
      * Fetching schema and other metadata
  """

  @typedoc """
  Data types that can be stored and retrieved from an ArcGIS feature service.
  """
  @type storage_type ::
          :binary
          | :datetime
          | :decimal
          | :geometry
          | :id
          | :integer
          | :object_id
          | :image
          | :decimal
          | :integer_small
          | :text
          | :xml

  @spec client_id :: String.t() | nil
  @doc """
  Fetches the default portal client ID, if one was set via application configuration.
  """
  def client_id, do: Application.get_env(:arcgis, :portal_client_id)
end
