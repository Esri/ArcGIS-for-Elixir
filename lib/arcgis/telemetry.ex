defmodule ArcGIS.Telemetry do
  @moduledoc false
  require Logger

  @type handle_success_options :: [
          {:log, boolean}
          | {:telemetry, boolean}
          | {:metadata, map}
        ]
  @spec handle_success(info :: map, handle_error_options) :: :ok
  @doc "Standardized handling of ArcGIS response success."
  def handle_success(info, options) do
    metadata = Keyword.get(:metadaa, %{})

    if Application.get_env(:arcgis, :log_errors, false) or Keyword.get(options, :log) == true do
      Logger.debug("Request SUCCEEDED:#{inspect(info)} => #{inspect(metadata)}")
    end

    if Application.get_env(:arcgis, :telemetry, true) or Keyword.get(options, :telemetry) == true do
      :telemetry.execute(
        [:arcgis, :request, :success],
        info,
        metadata
      )
    end

    :ok
  end

  @type handle_error_options :: [
          {:log, boolean}
          | {:telemetry, boolean}
          | {:metadata, map()}
        ]
  @spec handle_error({:error, term} | {:ok, Req.Response.t()}, handle_error_options) ::
          {:error, String.t()}
  @doc "Standardized handling of ArcGIS response errors."
  def handle_error(error, options \\ []) do
    {:error, message, metadata} = extract_error(error)
    metadata = Map.merge(Keyword.get(options, :metadata, %{}), metadata)

    if Application.get_env(:arcgis, :log_errors, true) or Keyword.get(options, :log) == true do
      Logger.warning("Request FAILED: #{inspect(metadata)} => #{inspect(message)}")
    end

    if Application.get_env(:arcgis, :telemetry, true) or Keyword.get(options, :telemetry) == true do
      # add the url requested if it was provided
      metadata =
        case Keyword.get(options, :url) do
          url when is_binary(url) -> Map.put(metadata, :request_url, url)
          _ -> metadata
        end

      :telemetry.execute(
        [:arcgis, :request, :error],
        %{message: message},
        metadata
      )
    end

    {:error, message}
  end

  defp extract_error({:ok, %Req.Response{body: %{"error" => error}}}) do
    {
      :error,
      error["message"],
      %{
        details: Map.get(error, "details"),
        status: Map.get(error, "code")
      }
    }
  end

  defp extract_error({:ok, %Req.Response{} = response}) do
    {:error, "#{inspect(response.body)}", %{status: response.status}}
  end

  defp extract_error({:error, %Req.TransportError{reason: reason}}) do
    {:error, reason, %{}}
  end

  defp extract_error({:error, error}) do
    {:error, error, %{}}
  end

  defp extract_error(error) do
    {:error, error, %{}}
  end
end
