defmodule ArcGIS.Feature.Service.CreateParameters do
  defstruct [
    :name,
    :spatial_reference,
    capabilities: [:query, :create, :update, :delete, :editing],
    has_static_data: false,
    max_record_count: 50_000,
    folder_id: nil,
    description: nil
  ]

  @type capability :: :query | :create | :update | :delete | :editing
  @type t :: %__MODULE__{
          name: String.t(),
          spatial_reference: non_neg_integer,
          capabilities: [capability],
          has_static_data: boolean,
          max_record_count: non_neg_integer,
          folder_id: String.t() | nil,
          description: String.t() | nil
        }
end
