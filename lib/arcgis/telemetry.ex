defmodule ArcGIS.Telemetry do
  @moduledoc false
  require Logger

  defstruct measurements: %{},
            metadata: %{},
            force_logging: false,
            force_telemetry: false

  @type t :: %__MODULE__{
          measurements: map,
          metadata: map,
          force_logging: boolean,
          force_telemetry: boolean
        }

  @spec handle_success(t()) :: :ok
  @doc "Standardized handling of ArcGIS response success."
  def handle_success(%__MODULE__{} = telemetry \\ %__MODULE__{}) do
    if telemetry.force_logging or Application.get_env(:arcgis, :log_success, false) do
      Logger.info(
        "ArcGIS request SUCCEEDED: #{inspect(telemetry.measurements)} => #{inspect(telemetry.metadata)}"
      )
    end

    if telemetry.force_telemetry or Application.get_env(:arcgis, :telemetry, true) do
      :telemetry.execute(
        [:arcgis, :request, :success],
        telemetry.measurements,
        telemetry.metadata
      )
    end

    :ok
  end

  @spec handle_error({:error, term} | {:ok, Req.Response.t()}, t()) ::
          {:error, String.t()}
  @doc "Standardized handling of ArcGIS response errors."
  def handle_error(error, %__MODULE__{} = telemetry \\ %__MODULE__{}) do
    {:error, message, metadata} = extract_error(error)
    metadata = Map.merge(telemetry.metadata, metadata) |> Map.put(:message, message)

    if telemetry.force_logging or Application.get_env(:arcgis, :log_errors, false) do
      Logger.warning(
        "ArcGIS request FAILED: #{inspect(telemetry.measurements)} => #{inspect(metadata)}"
      )
    end

    if telemetry.force_telemetry or Application.get_env(:arcgis, :telemetry, true) do
      :telemetry.execute(
        [:arcgis, :request, :error],
        telemetry.measurements,
        Map.put(telemetry.metadata, :message, message)
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
