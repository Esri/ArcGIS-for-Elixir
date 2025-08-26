defmodule ArcGIS.FeatureService do
  alias ArcGIS.FeatureService.Schema
  alias ArcGIS.Portal

  defstruct [:portal, :feature_service_id]

  @type t() :: %__MODULE__{
          portal: Portal.t(),
          feature_service_id: String.t()
        }

  def url(feature_service_id, options \\ []) do
    Cachex.get(:feature_service_urls, feature_service_id)
    |> possibly_cached_url(feature_service_id, options)
  end

  defp possibly_cached_url({:ok, url}, _feature_service_id, _options) when url != nil do
    {:ok, url}
  end

  defp possibly_cached_url(_, feature_service_id, options) do
    path = Path.join("/content/items", feature_service_id)

    with request_params <- Portal.request_url(path, options),
         {:ok, %Req.Response{body: %{"url" => url}}} when url != nil <- Req.get(request_params) do
      result = URI.parse(url)
      Cachex.put(:feature_service_urls, feature_service_id, result)
      {:ok, result}
    else
      error -> Portal.handle_error(error)
    end
  end

  def schema(feature_service_id, options \\ []) do
    with {:ok, %{"layers" => layers, "tables" => tables}} <-
           query_service(feature_service_id, "/layers", options),
         {:ok, schema} <- Schema.resolve(layers, tables) do
      {:ok, schema}
    else
      error -> Portal.handle_error(error)
    end
  end

  def query_service(feature_service_id, resource, options) do
    with {:ok, url} <- url(feature_service_id, options),
         resource_url <- URI.append_path(url, resource),
         request_params <- Portal.request_url(resource_url, options),
         {:ok, %{body: body}} <- Req.get(request_params) do
      {:ok, body}
    else
      error -> Portal.handle_error(error)
    end
  end
end
