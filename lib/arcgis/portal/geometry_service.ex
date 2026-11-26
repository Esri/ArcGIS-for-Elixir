defmodule ArcGIS.Portal.GeometryService do
  @moduledoc """
  The ArcGIS Portal geometry service which contains utility methods which provide 
  access to sophisticated and frequently used geometric operations. You can use this
  geometry service to buffer, project, and simplify geometry; calculate areas and 
  lengths for geometry; and determine spatial relations and label points.

  Discovered Portals (see `ArcGIS.Portal.discover/2`) should be used with this module
  for best performance.
  """
  require Logger

  def areas_and_lengths(%ArcGIS.Portal{} = portal) do
  end

  def auto_complete(%ArcGIS.Portal{} = portal) do
  end

  def buffer(%ArcGIS.Portal{} = portal) do
  end

  def convex_hull(%ArcGIS.Portal{} = portal) do
  end

  def cut(%ArcGIS.Portal{} = portal) do
  end

  def densify(%ArcGIS.Portal{} = portal) do
  end

  def difference(%ArcGIS.Portal{} = portal) do
  end

  def generalize(%ArcGIS.Portal{} = portal) do
  end

  def intersect(%ArcGIS.Portal{} = portal) do
  end

  def find_transformations(%ArcGIS.Portal{} = portal) do
  end

  def from_geo_coordinate_string(%ArcGIS.Portal{} = portal) do
  end

  def label_points(%ArcGIS.Portal{} = portal) do
  end

  def lengths(%ArcGIS.Portal{} = portal) do
  end

  def offset(%ArcGIS.Portal{} = portal) do
  end

  defmodule ProjectRequest do
    @enforce_keys [:geometries, :out_srid]
    defstruct [:geometries, :out_srid]
    
    @type t :: %{
      geometries: [Geometry.t()],
      out_srid: pos_integer(),
    }
  end

  @doc """
  Takes a list of geometries, and returns them projected into another spatial reference.
  """
  @spec project(
          ArcGIS.Portal.t(),
          project_request :: ProjectRequest.t(),
          options :: ArcGIS.Portal.portal_options()
        ) :: {:ok, term()} | {:error, reason :: String.t()}
  def project(%ArcGIS.Portal{} = portal, %ProjectRequest{geometries: [%x{} = exemplar_geometry | _]} = request, options) do
    geometry_type = ArcGIS.Portal.geometry_type(exemplar_geometry)

    params = %{
      "geometries" =>
        JSON.encode!(%{
          "geometryType" => geometry_type,
          "geometries" => just_geometries(request.geometries)
        }),
      "inSR" => exemplar_geometry.srid,
      "outSR" => request.out_srid
    }

    request(%ArcGIS.Portal{} = portal, "/project", params, options)
  end

  def relation(%ArcGIS.Portal{} = portal) do
  end

  def reshape(%ArcGIS.Portal{} = portal) do
  end

  def simplify(%ArcGIS.Portal{} = portal) do
  end

  def to_geo_coordinate_string(%ArcGIS.Portal{} = portal) do
  end

  def trim_extend(%ArcGIS.Portal{} = portal) do
  end

  def union(%ArcGIS.Portal{} = portal) do
  end

  defp request(%ArcGIS.Portal{} = portal, endpoint, params, options) do
    service_url = url(portal, options)

    if service_url != nil do
      ArcGIS.Portal.post(
        portal,
        URI.append_path(service_url, endpoint),
        params,
        options
      )
    else
      {:error, "Geometry Service not found"}
    end
  end

  defp url(%ArcGIS.Portal{helper_services: %{"geometry" => %{url: %URI{} = url}}}, _options) do
    url
  end

  defp url(%ArcGIS.Portal{type: :unknown} = portal, options) do
    Logger.warning(
      "Geometry service was given a Portal that had not yet been discovered via Portal.disocver/2"
    )

    case ArcGIS.Portal.discover(portal, options) do
      {:ok, portal} -> url(portal, options)
      _ -> nil
    end
  end

  defp url(_poral, _options), do: nil
  
  defp just_geometries(geometries) do
    Enum.map(geometries, 
      fn %{rings: })
  end
end
