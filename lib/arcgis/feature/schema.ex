defmodule ArcGIS.Feature.Schema do
  @moduledoc """
  The tables and layers in a feature service.
  """
  alias ArcGIS.Feature.Domain
  alias ArcGIS.Feature.Schema.Field
  alias ArcGIS.Feature.Service
  alias ArcGIS.Telemetry

  @typedoc "Description of the storage for a table or layer"
  @type store :: %{
          type: :layer | :table,
          id: String.t(),
          fields: [Field.t()],
          geometry: :none | atom
        }

  @typedoc "A schema, with names of tables and layers and their individual storage schemas"
  @type t :: %{[String.t()] => store}

  @spec get(Service.t(), Portal.portal_options()) :: {:ok, t()} | {:error, reason :: String.t()}
  @doc "Retrieves the schema for a feature service"
  def get(%Service{} = service, options) do
    with {:ok, %{"layers" => layers, "tables" => tables}} <-
           Service.get(service, "/layers", options),
         {:ok, schema} <- resolve(layers, tables) do
      {:ok, schema}
    else
      error -> error
    end
  end

  defp resolve(layers, tables) do
    {
      :ok,
      %{}
      |> extract(layers)
      |> extract(tables)
    }
  end

  defp extract(acc, entries) do
    Enum.reduce(entries, acc, fn layer, acc ->
      Map.put(acc, layer["name"], extract(layer))
    end)
  end

  defp extract(%{"type" => type} = table) do
    %{
      type: esri_table_type(type),
      id: table["id"],
      fields: process_fields(table["fields"], id_field_name(table)),
      geometry: geometry_field(table)
    }
  end

  defp geometry_field(%{"geometryType" => type}), do: esri_type_label(type)
  defp geometry_field(_table), do: :none

  defp process_fields(fields, id_field_name) do
    Enum.map(fields, fn field -> process_field(field, id_field_name) end)
  end

  defp process_field(field, id_field_name) do
    %Field{
      name: field["name"],
      label: field_label(field),
      editable?: field["editable"],
      primary_key?: field["name"] == id_field_name,
      domain: process_domain(field)
    }
    |> add_type(field, id_field_name)
  end

  defp field_label(%{"alias" => "", "name" => name}), do: name
  defp field_label(%{"alias" => field_alias}), do: field_alias

  defp process_domain(%{"domain" => %{"type" => "codedValue", "codedValues" => values} = domain}) do
    %Domain.Enum{
      name: domain["name"],
      values:
        Enum.reduce(values, %{}, fn %{"name" => label, "code" => value}, acc ->
          Map.put(acc, label, value)
        end)
    }
  end

  defp process_domain(%{
         "domain" => %{"type" => "range", "name" => name, "range" => [min, max | _]}
       }) do
    %Domain.Range{
      name: name,
      min: min,
      max: max
    }
  end

  defp process_domain(_field), do: %Domain.None{}

  defp add_type(processed_field, %{"name" => field_name, "type" => esri_type}, id_field_name) do
    processed_field
    |> Map.put(:type, esri_type)
    |> Map.put(:type_label, esri_type_label(esri_type))
    |> Map.put(:foreign_key?, type_is_foreign_id(esri_type, field_name, id_field_name))
  end

  defp type_is_foreign_id("GlobalID", field_name, field_name), do: false
  defp type_is_foreign_id("GlobalID", _field_name, _global_id_field_name), do: true
  defp type_is_foreign_id("esriFieldTypeGUID", _field_nam, _global_id_field_name), do: true
  defp type_is_foreign_id(_type, _field_name, _global_id_field_name), do: false

  defp id_field_name(%{"globalIdField" => field}), do: field
  defp id_field_name(_), do: "GlobalID"

  defp esri_table_type("Feature Layer"), do: :layer
  defp esri_table_type("Table"), do: :table

  defp esri_type_label("esriFieldTypeBlob"), do: :binary
  defp esri_type_label("esriFieldTypeDate"), do: :datetime
  defp esri_type_label("esriFieldTypeDouble"), do: :decimal
  defp esri_type_label("esriFieldTypeGeometry"), do: :geometry
  defp esri_type_label("esriFieldTypeGlobalID"), do: :id
  defp esri_type_label("esriFieldTypeGUID"), do: :id
  defp esri_type_label("esriFieldTypeInteger"), do: :integer
  defp esri_type_label("esriFieldTypeOID"), do: :object_id
  defp esri_type_label("esriFieldTypeRaster"), do: :image
  defp esri_type_label("esriFieldTypeSingle"), do: :decimal
  defp esri_type_label("esriFieldTypeSmallInteger"), do: :integer_small
  defp esri_type_label("esriFieldTypeString"), do: :text
  defp esri_type_label("esriFieldTypeXML"), do: :xml
  defp esri_type_label("esriGeometryMultipoint"), do: :multipoint
  defp esri_type_label("esriGeometryPoint"), do: :point
  defp esri_type_label("esriGeometryPolygon"), do: :polygon
  defp esri_type_label("esriGeometryPolyline"), do: :polyline
end
