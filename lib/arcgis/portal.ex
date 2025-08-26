defmodule ArcGIS.Portal do
  require Logger

  defstruct [:portal_url, :services_url]

  @type t :: %__MODULE__{
          portal_url: String.t(),
          services_url: String.t()
        }

  @type url_entries :: {:portal, url :: String.t()} | {:services, url :: String.t()}
  @type urls :: %{urls: [url_entries]}
  @type url_meta :: %{String.t() => String.t()}
  @type portal_options :: [
          {:headers, url_meta}
          | {:params, url_meta}
          | {:auth_token, String.t()}
        ]
  @spec request_url(relative_path :: String.t(), portal_options) ::
          [url: String.t(), params: url_meta, headers: url_meta]
  def request_url(relative_path, options \\ []) do
    url =
      relative_path
      |> URI.parse()
      |> create_url(options)
      |> to_string()

    params =
      Keyword.get(options, :params, %{})
      |> Map.put("clientId", Application.get_env(:arcgis, :portal_client_id))
      |> Map.put("f", "json")

    headers =
      Keyword.get(options, :headers, %{})
      |> add_token_header(Keyword.get(options, :auth_token))

    [url: url, params: params, headers: headers]
  end

  def is_error_response?({:error, _error}), do: true
  def is_error_response?({:ok, %Req.Response{body: %{"error" => _error}}}), do: true
  def is_error_response?(_), do: false

  def handle_error(error, options \\ [log: true]) do
    {:error, msg} = full_error = extract_error(error)

    if Keyword.get(options, :log) == true do
      Logger.warning("#{inspect(msg)}")
    end

    full_error
  end

  defp extract_error({:ok, %Req.Response{body: %{"error" => error}}}) do
    {:error, "#{error["messageCode"]}#{error["message"]}"}
  end

  defp extract_error({:error, error}) do
    {:error, error}
  end

  defp extract_error(error) do
    {:error, error}
  end

  defp add_token_header(headers, nil), do: headers

  defp add_token_header(headers, token) do
    Map.put(headers, "x-esri-authorization", "Bearer #{token}")
  end

  defp create_url(%{scheme: nil, path: relative_path}, options) do
    Keyword.get(options, :dest)
    |> base_url(options)
    |> URI.parse()
    |> URI.append_path(relative_path)
  end

  defp create_url(url, _options), do: url

  defp base_url(nil, options), do: base_url(:portal_url, options)

  defp base_url(dest, options) do
    options
    |> Keyword.get(:portal, %{})
    |> Map.get_lazy(dest, fn -> base_url_fallback(dest) end)
  end

  defp base_url_fallback(dest) do
    Application.get_env(:arcgis, :portal)
    |> Map.get(dest)
  end
end
