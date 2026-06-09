defmodule ArcGIS.Feature.Service.CreateParameters do
  @moduledoc "See https://developers.arcgis.com/rest/users-groups-and-items/create-service/"

  # TODO: consider adding the following fields:
  # copyrightText
  # initialExtent
  # xssPreventionInfo
  # serviceDescription
  defstruct [
    :name,
    :spatial_reference,
    capabilities: [:query, :create, :update, :delete, :editing],
    owner: nil,
    allow_geometry_updates: true,
    has_static_data: false,
    max_record_count: 50_000,
    folder_id: nil,
    description: nil,
    editor_tracking: false
  ]

  @typedoc "Access capaibilties for the server"
  @type capability :: :query | :create | :update | :delete | :editing

  @typedoc "Parameters to be used in the creation of a new feature service"
  @type t :: %__MODULE__{
          name: String.t(),
          spatial_reference: non_neg_integer,
          capabilities: [capability],
          allow_geometry_updates: boolean,
          has_static_data: boolean,
          max_record_count: non_neg_integer,
          owner: String.t() | nil,
          folder_id: String.t() | nil,
          description: String.t() | nil,
          editor_tracking: boolean
        }
end
