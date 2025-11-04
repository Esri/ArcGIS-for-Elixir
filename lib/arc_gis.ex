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

  @spec error_response?({:error, term} | {:ok, Req.Response.t()}) :: boolean
  @doc "Checks if the response from an ArcGIS REST query represents an error"
  def error_response?({:error, _error}), do: true

  def error_response?({:ok, %Req.Response{status: status}}) when status < 200 or status > 299,
    do: true

  def error_response?({:ok, %Req.Response{body: %{"error" => _error}}}), do: true
  def error_response?({:ok, %Req.Response{body: %{}}}), do: true
  def error_response?(_), do: false

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
    Application.get_env(:arcgis, :default_query_timeoute, @five_minutes)
  end

  @doc false
  def get(request) do
    with {:ok, %{body: body} = response} <- Req.get(request),
         false <- error_response?(response) do
      {:ok, body}
    else
      error -> ArcGIS.Telemetry.handle_error(error)
    end
  end

  @doc false
  def post(request, args) do
    with {:ok, %{body: body} = response} <- Req.post(request, args),
         false <- error_response?(response) do
      {:ok, body}
    else
      error -> ArcGIS.Telemetry.handle_error(error)
    end
  end
end
