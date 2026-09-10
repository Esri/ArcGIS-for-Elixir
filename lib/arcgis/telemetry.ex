# Copyright 2026 Esri
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
    metadata = extract_error(error)
    metadata = Map.merge(telemetry.metadata, metadata)

    if telemetry.force_logging or Application.get_env(:arcgis, :log_errors, false) do
      Logger.warning(
        "ArcGIS request FAILED: #{inspect(telemetry.measurements)} => #{inspect(metadata)}"
      )
    end

    if telemetry.force_telemetry or Application.get_env(:arcgis, :telemetry, true) do
      :telemetry.execute(
        [:arcgis, :request, :error],
        telemetry.measurements,
        metadata
      )
    end

    {:error, metadata.message}
  end

  defp extract_error({:ok, %Req.Response{body: %{"error" => error}}}) do
    %{
      message: error["message"],
      details: Map.get(error, "details"),
      status_code: Map.get(error, "code")
    }
  end

  defp extract_error({:ok, %Req.Response{} = response}) do
    %{message: "#{inspect(response.body)}", status: response.status}
  end

  defp extract_error({:error, %Req.TransportError{reason: reason}}) do
    %{message: reason}
  end

  defp extract_error({:error, error}) do
    %{message: error}
  end

  defp extract_error(error) do
    %{message: error}
  end
end
