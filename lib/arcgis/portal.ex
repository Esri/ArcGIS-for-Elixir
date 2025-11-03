defmodule ArcGIS.Portal do
  @moduledoc """
  An ArcGIS Portal. This may refer to an ArcGIS Online endpoint or an ArcGIS Enterprise installation.
  """
  require Logger

  alias ArcGIS.Telemetry
  alias ArcGIS.Utils

  defstruct [:base_url]

  @typedoc "A portal item ID"
  @type id :: String.t()

  @typedoc """
  The configuration of an ArcGIS portal necessary for its use, in particular the base_url
  """
  @type t :: %__MODULE__{
          base_url: URI.t()
        }

  @type url_meta :: %{String.t() => String.t()}
  @type portal_option ::
          {:auth_token, String.t()}
          | {:client_id, String.t()}
          | {:headers, url_meta}
          | {:params, url_meta}
          | {:portal, t()}
          | {:referer, String.t()}

  @type aggregate_type :: :avg | :count | :max | :min | :sum
  @type aggregate :: %{type: aggregate_type, field: String.t(), name: String.t()}
  @type response_format :: :geojson | :htmnl | :json | :pbf
  @type query_option ::
          {:is_features_query?, :boolean}
          | {:aggregates, [aggregate]}
          | {:fields, [String.t()]}
          | {:geometry?, boolean}
          | {:limit, non_neg_integer()}
          | {:offset, non_neg_integer()}
          | {:response_format, response_format}
          | {:where, String.t()}
  @type request_option :: portal_option | query_option

  @spec new(url :: String.t()) :: t()
  @doc "Create a `t:Portal.t/0` from its base URL."
  def new(url), do: %__MODULE__{base_url: URI.new!(url)}

  @spec self(t(), options :: [portal_option]) :: {:ok, map} | {:error, reason :: String.t()}
  @doc "Returns information about the Portal using the `self` query"
  def self(%__MODULE__{} = portal, options \\ []) do
    request = build_request("/portals/self", Keyword.put(options, :portal, portal))

    with {:ok, %{body: body}} <- Req.get(request) do
      {:ok, body}
    else
      error -> Telemetry.handle_error(error)
    end
  end

  @spec build_request(relative_path :: String.t(), [request_option]) ::
          [url: String.t(), params: url_meta, headers: url_meta]
  @doc """
  Returns the url, parameters, and headers for an HTTP request given a path to an endpoint relative to the
  Portal's default URL and additional options such as authentication information.

  By default, results are requested in JSON format.
  """
  def build_request(relative_path, options \\ []) do
    url =
      relative_path
      |> URI.parse()
      |> create_sharing_api_url(options)
      |> to_string()

    params =
      query_parameters(options, Keyword.get(options, :is_features_query?, true))
      |> Map.put(:clientId, client_id(options))
      |> Map.put(:f, response_format(options))
      |> Map.merge(Keyword.get(options, :params, %{}))

    headers =
      %{}
      |> add_token_header(Keyword.get(options, :auth_token))
      |> Map.merge(Keyword.get(options, :headers, %{}))

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

  @spec query_parameters(options :: [query_option], is_features_query? :: boolean) :: map
  defp query_parameters(_options, false), do: %{}

  defp query_parameters(options, true) do
    %{
      where:
        options
        |> Keyword.get(:where)
        |> where(),
      outFields:
        options
        |> Keyword.get(:fields)
        |> out_fields(),
      returnGeometry: Keyword.get(options, :geometry?, false),
      resultRecordCount: Keyword.get(options, :limit) |> Utils.to_integer(10),
      resultOffset: Keyword.get(options, :offset) |> Utils.to_integer(0)
    }
    |> add_aggregates(Keyword.get(options, :aggregates))
  end

  defp add_aggregates(args, nil), do: args

  defp add_aggregates(args, aggregates) do
    args
    |> Map.delete(:outFields)
    |> Map.delete(:resultRecordCount)
    |> Map.delete(:resultOffset)
    |> Map.put(:outStatistics, to_aggregate_form(aggregates))
  end

  defp to_aggregate_form(aggregates) do
    Enum.map(
      aggregates,
      fn aggregate ->
        %{
          statisticType: aggregate.type,
          onStatisticField: aggregate.field,
          outStatisticFieldName: aggregate.name
        }
      end
    )
    |> :json.encode()
    |> to_string()
  end

  defp where(nil), do: "1=1"
  defp where(filter), do: filter

  defp out_fields(nil), do: "*"
  defp out_fields(fields), do: Enum.join(fields, ",")
end
