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

defmodule ArcGIS.AsyncJob do
  @moduledoc """
  ArcGIS supports running various requests asyncronously.

  In these cases, the response to a request is a document with a status
  and a URL. While the job is not completed, the URL updates the status
  of the job. When it is completed, the URL returns the results (if any).

  Passing `async: true` to requests made through an `ArcGIS.Portal` will
  attempt to run the request asyncronously, and on success will return an
  `%ArcGIS.AsyncJob{}` struct.

  To check on a job's status, pass an `%ArcGIS.AsyncJob{}` struct to 
  `ArcGIS.AyncJob.update/2`.
  """
  alias ArcGIS.Telemetry

  defstruct [:status, :url]

  @type job_status ::
          :pending | :in_progress | :completed_successfully | :completed_with_errors | :unknown

  @type t :: %__MODULE__{
          status: job_status,
          url: String.t()
        }

  @spec valid_response?(term()) :: boolean()
  @doc """
  If the passed in parameter is an async job, returns true.
  """
  def valid_response?(%{"statusUrl" => _}), do: true
  def valid_response?(%{"resultUrl" => _}), do: true
  def valid_response?(_), do: false

  @spec from_response(term()) :: t()
  @doc """
  Creates an `%ArcGIS.AsyncJob{}` from a raw response map
  """
  def from_response(response) when is_map(response) do
    status = Map.get(response, "status", "") |> String.downcase() |> to_status()
    url = Map.get(response, "resultUrl") || Map.get(response, "statusUrl")
    %__MODULE__{status: status, url: url}
  end

  @spec update(t(), options :: ArcGIS.Portal.portal_options()) ::
          {:ok, t()} | {:ok, t(), map()} | {:error, reason :: String.t()}
  @doc """
  Attempts to fetch the update URL of the async job passed in,
  and returns a new `%ArcGIS.AsyncJob{}` struct.

  On job completion, any job result data will be returned as the 
  third member of the returned tuple.
  """
  def update(%__MODULE__{} = job, options \\ []) do
    request = build_request(job.url, options)

    telemetry =
      options
      |> Keyword.get(:telemetry, %Telemetry{})
      |> Kernel.put_in([Access.key!(:metadata), :http_method], :get)
      |> Kernel.put_in([Access.key!(:metadata), :url], job.url)

    get_args = [
      request_timeout: Keyword.get(options, :timeout, ArcGIS.default_query_timeout())
    ]

    with {:ok, %{body: body}} = response <- Req.get(request, get_args),
         :noerror <- ArcGIS.check_for_error(response) do
      Telemetry.handle_success(telemetry)

      if valid_response?(body) do
        {:ok, from_response(body)}
      else
        {:ok, job, body}
      end
    else
      error -> Telemetry.handle_error(error, telemetry)
    end
  end

  defp to_status("pending"), do: :pending

  defp to_status("executing"), do: :in_progress
  defp to_status("inprogress"), do: :in_progress
  defp to_status("partial"), do: :in_progress
  defp to_status("processing"), do: :in_progress

  defp to_status("completed"), do: :completed_successfully

  defp to_status("completedwitherrors"), do: :completed_with_errors
  defp to_status("failed"), do: :completed_with_errors
  defp to_status(_), do: :unknown

  defp build_request(url, options) do
    params =
      %{}
      |> Map.put(:clientId, ArcGIS.Portal.client_id(options))
      |> Map.put(:f, ArcGIS.Portal.response_format(options))
      |> Map.merge(Keyword.get(options, :params, %{}))

    headers =
      %{}
      |> ArcGIS.Portal.add_token_header(Keyword.get(options, :auth_token))
      |> Map.merge(Keyword.get(options, :headers, %{}))

    [url: url, params: params, headers: headers]
    |> Keyword.merge(Application.get_env(:arcgis, :req_defaults, []))
  end
end
