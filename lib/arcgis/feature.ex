defmodule ArcGIS.Feature do
  alias ArcGIS.Feature.{Schema, Service, Query}
  alias ArcGIS.Portal
  alias ArcGIS.Telemetry

  # TODO: define geometry properly
  @type feature_geometry :: map
  @typedoc "An ArcGIS feature made up of attributes and geometry"
  @type t :: %{geometry: feature_geometry, attributes: map}
  @type features_by_id :: [non_neg_integer]
  @type features_by_global_id :: [String.t()]
  @type mutations :: %{
          optional(:create) => [t()],
          optional(:update) => [t()],
          optional(:delete) => [features_by_id] | [features_by_global_id]
        }
  @type mutations_by_layer_id :: %{non_neg_integer => mutations}

  @type mutate_options :: [{:rollbackOnFailure, boolean}]

  @five_minutes 5 * 60 * 1000

  @doc "Query features in a Feature Service layer or table"
  def query(%Service{} = feature_service, layer_id, options \\ []) do
    params = Query.args(options)

    all_options =
      options
      |> Keyword.put(:params, params)
      |> Keyword.put(:portal, feature_service.portal)

    with {:ok, url} <- Service.url(feature_service),
         request_params <- Portal.request_url("#{url}/#{layer_id}/query", all_options),
         {:ok, %{body: %{"features" => features}}} <- Req.get(request_params) do
      {:ok, features}
    else
      error -> Telemetry.handle_error(error)
    end
  end

  # TODO: should this should return :ok/:error tuples?
  @spec mutate(
          Service.t(),
          mutations :: mutations_by_layer_id,
          options :: mutate_options
        ) :: boolean
  @doc "Add, update, and/or delete features from one or more layers."
  def mutate(feature_service, mutations, options \\ []) do
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
    params = Query.args(options)

    all_options =
      options
      |> Keyword.put(:params, params)
      |> Keyword.put(:useGlobalIds, true)

    post_args = [
      form: [edits: document],
      connect_options: [timeout: @five_minutes],
      receive_timeout: @five_minutes
    ]

    feature_service_url_request =
      case Service.url(feature_service) do
        {:ok, url} -> url
        error -> error
      end

    with feature_service_url when is_binary(feature_service_url) <- feature_service_url_request,
         url <- Portal.request_url("#{feature_service_url}/applyEdits", all_options),
         {:ok, response} <- Req.post(url, post_args),
         false <- ArcGIS.Portal.is_error_response?(response) do
      Telemetry.handle_success(%{action: :mutate}, metadata: %{request_url: url, method: :post})
      true
    else
      error ->
        # TODO: errors are per mutation (e.g. "addResults", "deleteResults"), per layer
        Telemetry.handle_error(error, url: feature_service_url_request)
        false
    end
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

  defp sanitize_feature(%{"attributes" => attributes} = feature, _schema) do
    %{feature | "attributes" => sanitize_attributes(attributes)}
  end

  defp sanitize_attributes(attributes) do
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
