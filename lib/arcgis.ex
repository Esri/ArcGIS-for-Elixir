defmodule ArcGIS do
  @moduledoc """
  Support for ArcGIS Online and ArcGIS Enterprise web APIs.

  Currently supported:

    * Simple user authentication
    * Portal API access
    * Feature services:
      * Querying and mutating features
      * Fetching schema and other metadata
  """

  @five_minutes 5 * 60 * 1000

  @typedoc """
  Data types that can be stored and retrieved from an ArcGIS feature service.
  """
  @type storage_type ::
          :binary
          | :datetime
          | :decimal
          | :geometry
          | :id
          | :integer
          | :object_id
          | :image
          | :decimal
          | :integer_small
          | :text
          | :xml

  @spec check_for_error(term) :: term | :noerror
  @doc "Checks if the response from an ArcGIS REST query represents an error"
  def check_for_error({:error, _error} = resp), do: resp

  def check_for_error({:ok, %Req.Response{status: status}} = resp)
      when status < 200 or status > 299 do
    resp
  end

  def check_for_error({:ok, %Req.Response{body: %{"error" => _error}}} = resp), do: resp
  def check_for_error({:ok, %Req.Response{body: body}} = resp) when map_size(body) == 0, do: resp
  def check_for_error(_), do: :noerror

  @spec client_id :: String.t() | nil
  @doc """
  Fetches the default portal client ID, if one was set via application configuration.
  """
  def client_id, do: Application.get_env(:arcgis, :portal_client_id)

  @spec default_query_timeout :: pos_integer
  @doc """
  Returns the configured default query timeout in millseconds. Defaults to 5 minutes.
  """
  def default_query_timeout do
    Application.get_env(:arcgis, :default_query_timeout, @five_minutes)
  end
end
