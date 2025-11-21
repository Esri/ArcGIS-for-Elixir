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

  @spec query(Service.t(), layer_id :: non_neg_integer(), [Portal.request_option()]) :: [t()]
  @doc "Query features in a Feature Service layer or table"
  def query(%Service{} = feature_service, layer_id, options \\ [])
      when is_number(layer_id) and layer_id >= 0 do
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
end
