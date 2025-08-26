defmodule ArcGIS do
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

  def client_id, do: Application.get_env(:arcgis, :portal_client_id)
end
