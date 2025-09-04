defmodule ArcGIS.Features do
  alias ArcGIS.FeatureService
  alias ArcGIS.Portal

  @type layer_definition :: %{
          required(:feature_service_id) => String.t(),
          required(:layer_Id) => non_neg_integer()
        }

  @type feature_geometry :: map
  @type add_content :: %{geometry: feature_geometry, attributes: map}
  @type update_content :: %{geometry: feature_geometry, attributes: map}
  @type delete_content_by_id :: [non_neg_integer]
  @type delete_content_by_global_id :: [non_neg_integer]
  @type mutations :: %{
          optional(:create) => [add_content],
          optional(:update) => [update_content],
          optional(:delete) => [delete_content_by_id] | [delete_content_by_global_id]
        }
  @type mutations_by_layer_id :: %{non_neg_integer => mutations}

  @type mutate_options :: [{:rollbackOnFailure, boolean}]

  @five_minutes 5 * 60 * 1000

  def query(feature_service_id, layer_id, options \\ []) do
    params = FeatureService.Query.args(options)
    all_options = Keyword.put(options, :params, params)

    with {:ok, url} <- FeatureService.url(feature_service_id, all_options),
         request_params <- Portal.request_url("#{url}/#{layer_id}/query", all_options),
         {:ok, %{body: %{"features" => features}}} <- Req.get(request_params) do
      {:ok, features}
    else
      error -> Portal.handle_error(error)
    end
  end

  @spec delete(layer :: layer_definition, options :: Keyword.t()) :: boolean
  def delete(layer, options \\ []) do
    params =
      Keyword.new()
      |> Keyword.put(:returnDeleteResults, false)
      |> FeatureService.Query.args()

    post_args = [
      form: Map.to_list(params),
      connect_options: [timeout: @five_minutes],
      receive_timeout: @five_minutes
    ]

    with {:ok, url} <- FeatureService.url(layer.feature_service_id, options),
         request_params <-
           Portal.request_url("#{url}/#{layer.layer_id}/deleteFeatures", options),
         {:ok, response} <- Req.post(request_params, post_args),
         false <- ArcGIS.Portal.is_error_response?(response) do
      IO.inspect(response, label: "Delete response")
      true
    else
      error ->
        Portal.handle_error(error)
        false
    end
  end

  @spec mutate(
          feature_service_id :: String.t(),
          mutations :: mutations_by_layer_id,
          options :: mutate_options
        ) :: boolean
  def mutate(feature_service_id, mutations, options \\ []) do
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

    # TODO: support non-globalID mutations
    params = FeatureService.Query.args(options)

    all_options =
      options
      |> Keyword.put(:params, params)
      |> Keyword.put(:useGlobalIds, true)

    post_args = [
      form: [edits: document],
      connect_options: [timeout: @five_minutes],
      receive_timeout: @five_minutes
    ]

    with {:ok, feature_service_url} <- FeatureService.url(feature_service_id, all_options),
         url <- Portal.request_url("#{feature_service_url}/applyEdits", all_options),
         {:ok, response} <- Req.post(url, post_args),
         false <- ArcGIS.Portal.is_error_response?(response) do
      # IO.inspect(response)
      # TODO: errors are per mutation (e.g. "addResults", "deleteResults"), per layer
      true
    else
      error ->
        Portal.handle_error(error)
        false
    end
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

  def sanitize(features) do
    # TODO: pass in the schema it should adhere to
    Enum.map(features, &sanitize_feature/1)
  end

  defp sanitize_feature(%{"attributes" => attributes} = feature) do
    %{feature | "attributes" => sanitize_attributes(attributes)}
  end

  defp sanitize_attributes(attributes) do
    # TODO: schema adherence
    Enum.reduce(attributes, %{}, &sanitize_attribute/2)
  end

  defp sanitize_attribute({key, value}, acc) do
    Map.put(acc, String.downcase(key), value)
  end
end
