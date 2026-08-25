# Copyright 2025 Esri
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

 defmodule ArcGIS.Feature do
  @moduledoc """
  Access to features in an ArcGIS feature service.
  """

  alias ArcGIS.Feature.Schema
  alias ArcGIS.Feature.Service
  alias ArcGIS.Telemetry

  # TODO: define geometry properly
  @type feature_geometry :: map
  @typedoc "An ArcGIS feature made up of attributes and geometry"
  @type t :: %{attributes: %{[key :: String.t()] => term}, geometry: feature_geometry}
  @type features_by_id :: [non_neg_integer]
  @type features_by_global_id :: [String.t()]
  @type mutations :: %{
          optional(:create) => [t()],
          optional(:update) => [t()],
          optional(:delete) => [features_by_id] | [features_by_global_id]
        }
  @type mutations_by_layer_id :: %{non_neg_integer => mutations}

  @type upload_format :: :json | :pbf
  @type mutate_option ::
          {:rollback_on_failure, boolean}
          | {:upload_format, upload_format}
          | {:use_global_ids, boolean}

  @spec from_map(source :: map, metadata :: map) :: t()
  @doc "Create a new feature struct from a map of data, such as returned by ArcGIS"
  def from_map(%{"geometry" => geometry} = data, %{geometry_type: geometry_type} = metadata) do
    srid =
      metadata
      |> Map.get(:spatial_reference, %ArcGIS.SpatialReference{})
      |> ArcGIS.SpatialReference.best_srid()

    %{
      attributes: data["attributes"],
      geometry: as_geometry(geometry_type, geometry, srid)
    }
  end

  def from_map(data, _metadata), do: data

  @spec query(Service.t(), layer_id :: non_neg_integer(), [Portal.request_option()]) :: [t()]
  @doc "Query features in a Feature Service layer or table"
  def query(%Service{} = feature_service, layer_id, options \\ [])
      when is_number(layer_id) and layer_id >= 0 do
    options = Keyword.put(options, :transform, &__MODULE__.from_map/2)
    Service.post(feature_service, "/#{layer_id}/query", [], options)
  end

  @spec mutate(
          Service.t(),
          mutations :: mutations_by_layer_id,
          options :: [Portal.request_option() | mutate_option]
        ) :: boolean
  @doc "Add, update, and/or delete features from one or more layers. Defaults to rolling back on failure."
  def mutate(service, mutations, options \\ []) do
    document =
      Enum.map(
        mutations,
        fn {layer_id, edits} ->
          %{id: layer_id}
          |> add_create(edits)
          |> add_update(edits)
          |> add_delete(edits)
        end
      )
      |> :json.encode()
      |> to_string()

    params = %{
      useGlobalIds: Keyword.get(options, :use_global_ids, true),
      rollbackOnFailure: Keyword.get(options, :rollback_on_failure, true),
      uploadFormat: Keyword.get(options, :upload_format, :json)
    }

    options_with_params =
      options
      |> Keyword.put(:params, params)
      |> Keyword.put(:telemetry, %Telemetry{
        metadata: %{service: service, action: :mutate_features}
      })

    # TODO: properly support PBF formats
    document = [edits: document]

    Service.post(service, "/applyEdits", document, options_with_params)
  end

  @spec sanitize(features :: [t()], schema :: Schema.t() | nil) :: [t()]
  @doc "Conforms a list of feature to ArcGIS requirements, making them appropriate for e.g. use in mutations"
  def sanitize(features, schema \\ nil) do
    # TODO: pass in the schema it should adhere to
    Enum.map(features, fn feature -> sanitize_feature(feature, schema) end)
  end

  defp add_create(arcgis_mutation, mutations) do
    features =
      mutations
      |> Map.get(:create, [])
      |> sanitize()

    Map.put(arcgis_mutation, :adds, features)
  end

  defp add_update(arcgis_mutation, mutations) do
    features =
      mutations
      |> Map.get(:updates, [])
      |> sanitize()

    Map.put(arcgis_mutation, :updates, features)
  end

  defp add_delete(arcgis_mutation, mutations) do
    Map.put(arcgis_mutation, :deletes, Map.get(mutations, :delete, []))
  end

  defp sanitize_feature(%{"attributes" => attributes} = feature, schema) do
    %{feature | "attributes" => sanitize_attributes(attributes, schema)}
  end

  defp sanitize_attributes(attributes, _schema) do
    # TODO: schema adherence
    # TODO: domain support
    # TODO: global ID brace wrapping
    Enum.reduce(attributes, %{}, &sanitize_attribute/2)
  end

  defp sanitize_attribute({key, value}, acc) when is_binary(key) do
    Map.put(acc, String.downcase(key), value)
  end

  defp sanitize_attribute({key, value}, acc) do
    Map.put(acc, key, value)
  end

  defp as_geometry(Geometry.Polygon, geometry, srid) do
    %Geometry.Polygon{rings: geometry["rings"], srid: srid}
  end

  defp as_geometry(Geometry.PolygonZ, geometry, srid) do
    %Geometry.PolygonZ{rings: geometry["rings"], srid: srid}
  end

  defp as_geometry(Geometry.PolygonM, geometry, srid) do
    %Geometry.PolygonM{rings: geometry["rings"], srid: srid}
  end

  defp as_geometry(Geometry.PolygonZM, geometry, srid) do
    %Geometry.PolygonZM{rings: geometry["rings"], srid: srid}
  end

  defp as_geometry(Geometry.MultiLineString, geometry, srid) do
    %Geometry.MultiLineString{line_strings: geometry["paths"], srid: srid}
  end

  defp as_geometry(Geometry.MultiLineStringZ, geometry, srid) do
    %Geometry.MultiLineStringZ{line_strings: geometry["paths"], srid: srid}
  end

  defp as_geometry(Geometry.MultiLineStringM, geometry, srid) do
    %Geometry.MultiLineStringM{line_strings: geometry["paths"], srid: srid}
  end

  defp as_geometry(Geometry.MultiLineStringZM, geometry, srid) do
    %Geometry.MultiLineStringZM{line_strings: geometry["paths"], srid: srid}
  end

  defp as_geometry(Geometry.MultiPoint, geometry, srid) do
    %Geometry.MultiPoint{points: geometry["points"], srid: srid}
  end

  defp as_geometry(Geometry.MultiPointZ, geometry, srid) do
    %Geometry.MultiPointZ{points: geometry["points"], srid: srid}
  end

  defp as_geometry(Geometry.MultiPointM, geometry, srid) do
    %Geometry.MultiPointM{points: geometry["points"], srid: srid}
  end

  defp as_geometry(Geometry.MultiPointZM, geometry, srid) do
    %Geometry.MultiPointZM{points: geometry["points"], srid: srid}
  end

  defp as_geometry(Geometry.PointZ, %{"x" => x, "y" => y, "z" => z}, srid) do
    Geometry.PointZ.new(x, y, z, srid)
  end

  defp as_geometry(Geometry.PointM, %{"x" => x, "y" => y, "m" => m}, srid) do
    Geometry.PointM.new(x, y, m, srid)
  end

  defp as_geometry(Geometry.PointZM, %{"x" => x, "y" => y, "z" => z, "m" => m}, srid) do
    Geometry.PointZM.new(x, y, z, m, srid)
  end

  defp as_geometry(Geometry.Point, %{"x" => x, "y" => y}, srid) do
    Geometry.Point.new(x, y, srid)
  end
end
