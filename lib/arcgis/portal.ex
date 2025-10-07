defmodule ArcGIS.Portal do
  @moduledoc """
  An ArcGIS Portal.
  """
  require Logger

  defstruct [:base_url]

  @typedoc """
  The configurateion of an ArcGIS portal necessary for its use,
  in particular the base_url
  """
  @type t :: %__MODULE__{
          base_url: String.t()
        }

  @type url_meta :: %{String.t() => String.t()}
  @type portal_options :: [
          {:auth_token, String.t()}
          | {:client_id, String.t()}
          | {:headers, url_meta}
          | {:response_format, String.t()}
          | {:params, url_meta}
          | {:portal, t()}
        ]
  @spec request_url(relative_path :: String.t(), portal_options) ::
          [url: String.t(), params: url_meta, headers: url_meta]
  @doc """
  Returns the url, parameters, and headers for an HTTP request given the relative path and the options passed in.

  By default, results are requested in JSON format.
  """
  def request_url(relative_path, options \\ []) do
    url =
      relative_path
      |> URI.parse()
      |> create_sharing_api_url(options)
      |> to_string()

    params =
      Keyword.get(options, :params, %{})
      |> Map.put("clientId", client_id(options))
      |> Map.put("f", response_format(options))

    headers =
      Keyword.get(options, :headers, %{})
      |> add_token_header(Keyword.get(options, :auth_token))

    [url: url, params: params, headers: headers]
  end

  @spec is_error_response?({:error, term} | {:ok, Req.Response.t()}) :: boolean
  @doc "Checks if the response from an ArcGIS REST query represents an error"
  def is_error_response?({:error, _error}), do: true

  def is_error_response?({:ok, %Req.Response{status: status}}) when status < 200 or status > 299,
    do: true

  def is_error_response?({:ok, %Req.Response{body: %{"error" => _error}}}), do: true
  def is_error_response?({:ok, %Req.Response{body: %{}}}), do: true
  def is_error_response?(_), do: false

  defp add_token_header(headers, nil), do: headers

  defp add_token_header(headers, token) do
    Map.put(headers, "x-esri-authorization", "Bearer #{token}")
  end

  defp client_id(options) do
    Keyword.get(options, :client_id, ArcGIS.client_id())
  end

  defp response_format(options) do
    Keyword.get(options, :response_format, "json")
  end

  defp create_sharing_api_url(%{scheme: nil, path: relative_path}, options) do
    options
    |> Keyword.get(:portal, %{})
    |> Map.get_lazy(:base_url, &base_url_fallback/0)
    |> URI.append_path("/sharing/rest")
    |> URI.append_path(relative_path)
  end

  defp create_sharing_api_url(url, _options), do: url

  defp base_url_fallback do
    Application.get_env(:arcgis, :portal)
    |> Map.get(:base_url)
  end
end
