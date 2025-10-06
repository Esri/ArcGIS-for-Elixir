defmodule ArcGIS.FeatureService do
  alias ArcGIS.FeatureService.Schema
  alias ArcGIS.Portal
  alias ArcGIS.Telemetry

  defstruct [:portal, :feature_service_id]

  @type t() :: %__MODULE__{
          portal: Portal.t(),
          feature_service_id: String.t()
        }

  def url(feature_service_id, options \\ []) do
    case Cachex.get(:feature_service_urls, feature_service_id) do
      {:ok, url} -> url
      _ -> fetch_and_cache_url(feature_service_id, options)
    end
  end

  defp fetch_and_cache_url(feature_service_id, options) do
    path = Path.join("/content/items", feature_service_id)
    request = Portal.request_url(path, options)

    case Req.get(request) do
      {:ok, %Req.Response{body: %{"url" => url}}} when url != nil ->
        result = URI.parse(url)
        Cachex.put(:feature_service_urls, feature_service_id, result)
        {:ok, result}

      error ->
        Telemetry.handle_error(error, url: Keyword.get(request, :url))
    end
  end

  def schema(feature_service_id, options \\ []) do
    with {:ok, %{"layers" => layers, "tables" => tables}} <-
           query_service(feature_service_id, "/layers", options),
         {:ok, schema} <- Schema.resolve(layers, tables) do
      {:ok, schema}
    else
      error -> Telemetry.handle_error(error)
    end
  end

  def query_service(feature_service_id, resource, options) do
    with {:ok, url} <- url(feature_service_id, options),
         resource_url <- URI.append_path(url, resource),
         request_params <- Portal.request_url(resource_url, options),
         {:ok, %{body: body}} <- Req.get(request_params) do
      {:ok, body}
    else
      error -> Telemetry.handle_error(error)
    end
  end
end
