defmodule ArcGIS.Feature.Service do
  @moduledoc """
  Feature service acccess.

  For fetching data from a feature service, see `ArcGIS.Feature`.
  """

  alias ArcGIS.Portal
  alias ArcGIS.Telemetry
  alias __MODULE__.CreateParameters

  @cache_name :feature_service_urls

  @enforce_keys [:id]
  defstruct [:portal, :id]

  @typedoc """
  Definition of a feature service including the Portal it is hosted on and the Feature Service's ID
  """

  @type t() :: %__MODULE__{
          portal: Portal.t(),
          id: String.t()
        }

  @spec create(Portal.t(), CreateParameters.t(), options :: Keyword.t()) ::
          {:ok, t()} | {:error, reason :: String.t()}
  def create(%Portal{} = portal, %CreateParameters{} = parameters, options) do
    # TODO: support the following? tags, snippet, overwrite, isView
    owner =
      cond do
        is_binary(parameters.owner) ->
          parameters.owner

        is_binary(Keyword.get(options, :auth_token)) ->
          {:ok, user} = ArcGIS.User.from_token(portal, Keyword.get(options, :auth_token))
          user.names.username
      end

    default_params = %{"supportedQueryFormats" => "JSON", "owner" => owner}

    params =
      Enum.reduce(Map.from_struct(parameters), default_params, &generate_create_document/2)
      |> :json.encode()
      |> to_string()

    post_options =
      [
        form: %{"outputType" => "featureService", "createParameters" => params},
        connect_options: [timeout: ArcGIS.default_query_timeout()],
        receive_timeout: ArcGIS.default_query_timeout()
      ]

    folder =
      case parameters.folder_id do
        nil -> ""
        id -> "/#{id}"
      end

    resource = "/content/users/#{owner}#{folder}/createService"

    request_options =
      options
      |> Keyword.put(:is_features_query?, false)

    request = Portal.build_request(portal, resource, request_options)

    case Portal.post(request, post_options) do
      {:ok, %{"itemId" => id, "serviceurl" => url}} ->
        service = %__MODULE__{portal: portal, id: id}
        cache(service, url)
        {:ok, service}

      {:error, _} = error ->
        error

      other_error ->
        Telemetry.handle_error(other_error)
    end
  end

  @spec get(t(), resource :: String.t(), options :: Keyword.t()) ::
          {:ok, map} | {:error, reason :: String.t()}
  def get(%__MODULE__{} = service, resource, options \\ []) do
    service
    |> build_request(resource, options)
    |> Portal.get(options)
  end

  @spec post(t(), resource :: String.t(), document :: Keyword.t(), options :: Keyword.t()) ::
          {:ok, map} | {:error, reason :: String.t()}
  def post(%__MODULE__{} = service, resource, document, options \\ []) do
    post_args = [
      form: document,
      connect_options: [timeout: ArcGIS.default_query_timeout()],
      receive_timeout: ArcGIS.default_query_timeout()
    ]

    service
    |> build_request(resource, options)
    |> Portal.post(post_args, options)
  end

  @spec url(t()) :: String.t()
  @doc """
  Returns the access URL for a feature service.
  """
  def url(%__MODULE__{} = service, options \\ []) do
    case Cachex.get(@cache_name, cache_key(service)) do
      {:ok, url} when url != nil ->
        Telemetry.handle_success(%Telemetry{measurements: %{service_cache_hit: 1}})
        {:ok, url}

      _ ->
        fetch_and_cache_url(service, options)
    end
  end

  @spec fetch_and_cache_url(t(), options :: Keyword.t()) :: {:ok, String.t()} | {:error, term}
  defp fetch_and_cache_url(service, options) do
    path = Path.join("/content/items", service.id)
    request = Portal.build_request(service.portal, path, options)

    case Portal.get(request, selector: ["url"]) do
      {:ok, url} ->
        result = cache(service, url)
        {:ok, result}

      error ->
        error
    end
  end

  @spec cache(t(), url :: String.t()) :: URI.t()
  defp cache(service, url) do
    uri = URI.parse(url)
    Cachex.put(@cache_name, cache_key(service), uri)
    uri
  end

  @spec cache_key(t()) :: String.t()
  defp cache_key(%__MODULE__{portal: %{base_url: url}, id: id}) do
    id <> "@" <> url.host
  end

  defp build_request(service, resource, options) do
    case url(service, auth_token: Keyword.get(options, :auth_token)) do
      {:ok, url} ->
        resource_url =
          if resource != nil do
            URI.append_path(url, resource)
          else
            url
          end

        Portal.build_request(service.portal, resource_url, options)

      error ->
        error
    end
  end

  defp generate_create_document({_, nil}, acc), do: acc
  defp generate_create_document({:capabilities, []}, acc), do: acc

  defp generate_create_document({:capabilities = key, capabilities}, acc) do
    capabilities_string = Enum.map_join(capabilities, ",", &Inflex.camelize/1)
    Map.put(acc, Inflex.camelize(key, :lower), capabilities_string)
  end

  defp generate_create_document({key, value}, acc)
       when key in [
              :allow_geometry_updates,
              :description,
              :has_static_data,
              :max_record_count,
              :name,
              :owner,
              :service_description
            ] do
    Map.put(acc, Inflex.camelize(key, :lower), value)
  end

  defp generate_create_document({_, nil}, acc), do: acc
end
