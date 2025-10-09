defmodule ArcGIS.Feature.Service do
  @moduledoc """
  Feature service acccess.

  For fetching data from a feature service, see `ArcGIS.Feature`.
  """

  alias ArcGIS.Feature.Schema
  alias ArcGIS.Portal
  alias ArcGIS.Telemetry

  @cache_name :feature_service_urls
  @five_minutes 5 * 60 * 1000

  @enforce_keys [:id]
  defstruct [:portal, :id]

  @typedoc """
  Definition of a feature service including the Portal it is hosted on and the Feature Service's ID
  """

  @type t() :: %__MODULE__{
          portal: Portal.t(),
          id: String.t()
        }

  @spec get(t(), resource :: String.t(), options :: Keyword.t()) ::
          {:ok, map} | {:error, reason :: String.t()}
  def get(%__MODULE__{} = service, resource, options \\ []) do
    request = build_request(service, resource, options)

    with {:ok, %{body: body}} <- Req.get(request) do
      {:ok, body}
    else
      error -> Telemetry.handle_error(error)
    end
  end

  @spec post(t(), resource :: String.t(), document :: Keyword.t(), options :: Keyword.t()) ::
          {:ok, map} | {:error, reason :: String.t()}
  def post(%__MODULE__{} = service, resource, document, options \\ []) do
    post_args = [
      form: document,
      connect_options: [timeout: @five_minutes],
      receive_timeout: @five_minutes
    ]

    request = build_request(service, resource, options)

    with {:ok, %{body: body} = response} <- Req.post(request, post_args),
         false <- ArcGIS.Portal.is_error_response?(response) do
      {:ok, body}
    else
      error ->
        error
    end
  end

  @spec url(t()) :: String.t()
  @doc """
  Returns the access URL for a feature service.
  """
  def url(%__MODULE__{} = service, options \\ []) do
    case Cachex.get(@cache_name, cache_key(service)) do
      {:ok, url} when url != nil -> {:ok, url}
      _ -> fetch_and_cache_url(service, options)
    end
  end

  @spec schema(t(), options :: Keyword.t()) :: {:ok, Schema.t()} | {:error, String.t()}
  @doc """
  Fetches the `Schema` for a feature service.
  """
  def schema(%__MODULE__{} = service, options \\ []) do
    with {:ok, %{"layers" => layers, "tables" => tables}} <-
           get(service, "/layers", options),
         {:ok, schema} <- Schema.resolve(layers, tables) do
      {:ok, schema}
    else
      error -> Telemetry.handle_error(error)
    end
  end

  @spec fetch_and_cache_url(t(), options :: Keyword.t()) :: {:ok, String.t()} | {:error, term}
  defp fetch_and_cache_url(service, options) do
    path = Path.join("/content/items", service.id)
    all_options = Keyword.put(options, :portal, service.portal)
    request = Portal.build_request(path, all_options)

    case Req.get(request) do
      {:ok, %Req.Response{body: %{"url" => url}}} when url != nil ->
        result = URI.parse(url)
        Cachex.put(@cache_name, cache_key(service), result)
        {:ok, result}

      error ->
        Telemetry.handle_error(error, url: Keyword.get(request, :url))
        error
    end
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

        Portal.build_request(resource_url, options)

      error ->
        error
    end
  end
end
