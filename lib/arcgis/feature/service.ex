defmodule ArcGIS.Feature.Service do
  @moduledoc """
  Feature service acccess.

  For fetching data from a feature service, see `ArcGIS.Feature`.
  """

  alias ArcGIS.Feature.Schema
  alias ArcGIS.Portal
  alias ArcGIS.Telemetry

  @enforce_keys [:id]
  defstruct [:portal, :id]

  @typedoc """
  Definition of a feature service including the Portal it is hosted on and the Feature Service's ID
  """

  @type t() :: %__MODULE__{
          portal: Portal.t(),
          id: String.t()
        }

  @spec url(t()) :: String.t()
  @doc """
  Returns the access URL for a feature service.
  """
  def url(%__MODULE__{} = feature_service) do
    case Cachex.get(:feature_service_urls, cache_key(feature_service)) do
      {:ok, url} -> url
      _ -> fetch_and_cache_url(feature_service)
    end
  end

  @spec schema(t()) :: {:ok, Schema.t()} | {:error, String.t()}
  @doc """
  Fetches the `Schema` for a feature service.
  """
  def schema(%__MODULE__{} = feature_service) do
    with {:ok, %{"layers" => layers, "tables" => tables}} <-
           query_service(feature_service, "/layers"),
         {:ok, schema} <- Schema.resolve(layers, tables) do
      {:ok, schema}
    else
      error -> Telemetry.handle_error(error)
    end
  end

  def query_service(%__MODULE__{} = feature_service, resource) do
    with {:ok, url} <- url(feature_service.id),
         resource_url <- URI.append_path(url, resource),
         request_params <- Portal.request_url(resource_url, portal: feature_service.portal),
         {:ok, %{body: body}} <- Req.get(request_params) do
      {:ok, body}
    else
      error -> Telemetry.handle_error(error)
    end
  end

  @spec fetch_and_cache_url(t()) :: String.t()
  defp fetch_and_cache_url(feature_service) do
    path = Path.join("/content/items", feature_service.id)
    request = Portal.request_url(path, portal: feature_service.portal)

    case Req.get(request) do
      {:ok, %Req.Response{body: %{"url" => url}}} when url != nil ->
        result = URI.parse(url)
        Cachex.put(:feature_service_urls, cache_key(feature_service), result)
        {:ok, result}

      error ->
        Telemetry.handle_error(error, url: Keyword.get(request, :url))
    end
  end

  @spec cache_key(t()) :: String.t()
  defp cache_key(%__MODULE__{portal: %{base_url: url}, id: id}) do
    id <> "@" <> url
  end
end
