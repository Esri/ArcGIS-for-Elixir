defmodule ArcGIS.Portal do
  @moduledoc """
  An ArcGIS Portal. This may refer to an ArcGIS Online endpoint or an ArcGIS Enterprise installation.
  """
  require Logger
  require ArcGIS.Portal.Macros

  alias ArcGIS.Portal.Macros
  alias ArcGIS.Telemetry
  alias ArcGIS.Utils

  @enforce_keys [:base_url]
  defstruct [:base_url, :help_url, type: :unknown, version: :unknown, verify_tls: true]

  @typedoc "A portal item ID"
  @type id :: String.t()

  @type portal_type :: :online | :enterprise | :unknown
  @type portal_version :: {year :: number, release :: number} | :unknown

  @typedoc """
  The configuration of an ArcGIS portal necessary for its use, in particular the base_url
  """
  @type t :: %__MODULE__{
          base_url: URI.t(),
          help_url: URI.t() | :unknown,
          type: portal_type,
          version: portal_version,
          verify_tls: boolean
        }

  @type url_meta :: %{String.t() => String.t()}
  @type portal_option ::
          {:auth_token, String.t()}
          | {:client_id, String.t()}
          | {:headers, url_meta}
          | {:params, url_meta}
          | {:portal, t()}

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
  @type request_data :: [url: String.t(), params: url_meta, headers: url_meta]

  @typedoc "A function that transforms raw ArcGIS results into a more prefereable form. Both one- and two-arity functions are supported, with the two arity receiving a map of metadata including such things as the spatial reference if available."
  @type transform_fn ::
          (source :: map -> transformed :: term)
          | (source :: map, metadata :: map -> transformed :: term)

  @type get_options :: {:selector, [term()]} | {:transform, transform_fn} | {:verify_tls, boolean}
  @type post_options ::
          {:selector, [term()]} | {:transform, transform_fn} | {:verify_tls, boolean}
  @type form_data :: map

  @arcgis_online_baseurl "https://arcgis.com/"

  @spec new(url :: String.t()) :: {:ok, t()} | {:error, reason :: String}
  @doc "Create a `t:Portal.t/0` from its base URL."
  def new(url) do
    {:ok, %__MODULE__{base_url: URI.new!(url)}}
  rescue
    _error -> {:error, "Bad portal #{inspect(url)}"}
  end

  @spec discover((portal_url :: String.t()) | t(), options :: [portal_option]) ::
          {:ok, t()} | {:error, reason :: String.t()}
  @doc """
  Discovers the version, type (`:online` or `:enterprise`), etc. of a portal and returns a new `%ArcGIS.Portal{}` with this information
  """
  def discover(portal, options \\ [])

  def discover(%__MODULE__{} = portal, options) do
    case self(portal, options) do
      {:ok, self} ->
        {
          :ok,
          %__MODULE__{
            portal
            | type: type_from_self(self),
              version: version_from_self(self),
              help_url: help_url_from_self(self)
          }
        }

      error ->
        error
    end
  end

  def discover(portal_url, options) when is_binary(portal_url) do
    case new(portal_url) do
      {:ok, portal} -> discover(portal, options)
      error -> error
    end
  end

  @spec self(t(), options :: [portal_option]) :: {:ok, map} | {:error, reason :: String.t()}
  @doc "Returns information about the Portal using the `self` query"
  def self(%__MODULE__{} = portal, options \\ []) do
    get(portal, "/portals/self", options)
  end

  @spec default_portal :: t()
  @doc """
  Returns the default portal. The portal (if any) defined in the
  application configuration will be used, with ArcGIS Online used as the ultimate fallback.
  """
  def default_portal do
    case Application.get_env(:arcgis, :portal) do
      %__MODULE__{} = portal -> portal
      _ -> new(@arcgis_online_baseurl)
    end
  end

  @spec only_portal_options(Keyword.t()) :: [portal_option()]
  @doc false
  def only_portal_options(options) do
    known_options = [:auth_token, :client_id, :headers, :params, :portal]

    Keyword.filter(
      options,
      fn {key, _value} -> Enum.member?(known_options, key) end
    )
  end

  @spec get(t(), resource :: String.t(), [get_options]) ::
          {:ok, Portal.ResultSet.t()} | {:ok, term} | {:error, reason :: String.t()}
  @doc """
  Performs an HTTP GET request, checking for errors.

  An optional `selector: [...]` may be passed in as an option to return
  only part of the response. For example, `selector: ["geometry", "srid"]`
  would return the `srid` in the `geometry` object if it exists, or an
  error tuple otherwise.

  If the results are paged, then a map with the next offset and results is returned.
  """
  def get(portal, resource, options \\ []) do
    request = build_request(portal, resource, options)

    telemetry =
      options
      |> Keyword.get(:telemetry, %Telemetry{})
      |> Kernel.put_in([Access.key!(:metadata), :http_method], :get)
      |> Kernel.put_in([Access.key!(:metadata), :url], Keyword.get(request, :url))

    get_args = [
      connect_options: transport_options(portal, options),
      receive_timeout: ArcGIS.default_query_timeout()
    ]

    with {:ok, %{body: body}} = response <- Req.get(request, get_args),
         :noerror <- ArcGIS.check_for_error(response) do
      Telemetry.handle_success(telemetry)
      select(body, options)
    else
      error -> Telemetry.handle_error(error, telemetry)
    end
  end

  @spec post(t(), resource :: String.t(), form_data, [post_options]) ::
          {:ok, Portal.ResultSet.t()} | {:ok, term} | {:error, reason :: String.t()}
  @doc """
  Performs an HTTP POST request, checking for errors.

  An optional `selector: [...]` may be passed in as an option to return
  only part of the response. For example, `selector: ["geometry", "srid"]`
  would return the `srid` in the `geometry` object if it exists, or an
  error tuple otherwise.
  """
  def post(portal, resource, form_data, options \\ []) do
    request = build_request(portal, resource, options)

    telemetry =
      options
      |> Keyword.get(:telemetry, %Telemetry{})
      |> Kernel.put_in([Access.key!(:metadata), :http_method], :post)
      |> Kernel.put_in([Access.key!(:metadata), :url], Keyword.get(request, :url))

    post_args =
      [
        form: form_data,
        connect_options: transport_options(portal, options),
        receive_timeout: ArcGIS.default_query_timeout()
      ]

    with {:ok, %{body: body}} = response <- Req.post(request, post_args),
         :noerror <- ArcGIS.check_for_error(response) do
      Telemetry.handle_success(telemetry)
      select(body, options)
    else
      error -> Telemetry.handle_error(error, telemetry)
    end
  end

  defp transport_options(portal, options) do
    app_transport_opts = Application.get_env(:arcgis, :tls_transport_opts, [])
    request_transport_opts = Keyword.get(options, :transport_opts, [])

    merged_transport_opts =
      Keyword.merge(app_transport_opts, request_transport_opts)

    no_tls =
      portal.verify_tls === false or
        Keyword.get(options, :verify_tls) === false

    base =
      if no_tls do
        [timeout: ArcGIS.default_query_timeout(), transport_opts: [verify: :verify_none]]
      else
        [timeout: ArcGIS.default_query_timeout(), transport_opts: []]
      end

    Keyword.update(base, :transport_opts, merged_transport_opts, fn existing ->
      Keyword.merge(existing, merged_transport_opts)
    end)
  end

  defp select(body, options) do
    case Keyword.get(options, :selector, []) do
      selector when selector != [] ->
        case Kernel.get_in(body, selector) do
          nil -> {:error, "Not found: #{inspect(selector)}"}
          data -> {:ok, transform_results(data, options)}
        end

      _ ->
        {:ok, handle_paged_body(body, options)}
    end
  end

  defp transform_results(results, options, metadata \\ %{}) do
    case Keyword.get(options, :transform) do
      nil ->
        results

      transform when is_function(transform, 1) ->
        if is_list(results) do
          Enum.map(results, transform)
        else
          transform.(results)
        end

      transform when is_function(transform, 2) ->
        if is_list(results) do
          Enum.map(results, fn result -> transform.(result, metadata) end)
        else
          transform.(results, metadata)
        end
    end
  end

  defp handle_paged_body(
         %{"objectIdFieldName" => _, "features" => results} = page,
         options
       ) do
    offset = Keyword.get(options, :offset, 0)

    spatial_reference =
      page
      |> Map.get("spatialReference", %{})
      |> ArcGIS.SpatialReference.from_map()

    geometry_type =
      geometry_module_for(
        Map.get(page, "geometryType", ""),
        Map.get(page, "hasZ", false),
        Map.get(page, "hasM", false)
      )

    metadata = %{spatial_reference: spatial_reference, geometry_type: geometry_type}

    %ArcGIS.Portal.ResultSet{
      results: transform_results(results, options, metadata),
      next_offset: offset + Enum.count(results),
      offset: offset,
      more?: Map.get(page, "exceededTransferLimit", false),
      spatial_reference: spatial_reference
    }
  end

  defp handle_paged_body(
         %{"results" => results, "nextStart" => offset, "start" => start} = page,
         options
       ) do
    %ArcGIS.Portal.ResultSet{
      results: transform_results(results, options),
      next_offset: offset,
      offset: start,
      more?: start + Enum.count(results) < page["total"]
    }
  end

  defp handle_paged_body(body, options), do: transform_results(body, options)

  def geometry_module_for("", _z, _m), do: :unknown
  Macros.geometry_module_for("esriGeometryMultipoint", "Geometry.MultiPoint")
  Macros.geometry_module_for("esriGeometryPoint", "Geometry.Point")
  Macros.geometry_module_for("esriGeometryPolygon", "Geometry.Polygon")
  Macros.geometry_module_for("esriGeometryPolyline", "Geometry.MultiLineString")

  @spec build_request(portal :: t(), relative_path :: String.t(), [request_option]) ::
          request_data
  # Returns the url, parameters, and headers for an HTTP request given a path to an endpoint relative to the
  # Portal's default URL and additional options such as authentication information.
  #
  # By default, results are requested in JSON format.
  defp build_request(%__MODULE__{} = portal, relative_path, options) do
    url =
      relative_path
      |> URI.parse()
      |> create_sharing_api_url(portal)
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
    |> Keyword.merge(Application.get_env(:arcgis, :req_defaults, []))
  end

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

  defp create_sharing_api_url(
         %{scheme: nil, path: relative_path},
         %__MODULE__{base_url: base_url} = _portal
       ) do
    base_url
    |> URI.append_path("/sharing/rest")
    |> URI.append_path(relative_path)
  end

  defp create_sharing_api_url(url, _portal), do: url

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

  defp version_from_self(%{"currentVersion" => version}) do
    with [year_string, release_string] <- String.split(version, "."),
         year when not is_nil(year) <- Utils.to_integer(year_string),
         release when not is_nil(release) <- Utils.to_integer(release_string) do
      {year, release}
    else
      _ -> :unknown
    end
  end

  defp version_from_self(_), do: :unknown

  defp type_from_self(%{"portalDeploymentType" => type}) do
    case type do
      "ArcGISEnterprise" -> :enterprise
      _ -> :unknown
    end
  end

  defp type_from_self(%{"portalHostname" => hostname}) do
    if String.ends_with?(hostname, "arcgis.com") do
      :online
    else
      :unknown
    end
  end

  defp type_from_self(_), do: :unknown

  defp help_url_from_self(self) do
    with %{"helpBase" => url_string} <- self,
         {:ok, uri} <- URI.new(url_string) do
      uri
    else
      _ -> :unknown
    end
  end
end
