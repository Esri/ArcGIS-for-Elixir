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

defmodule ArcGIS.Feature.MutationResult do
  @moduledoc """
  Helpers for validating ArcGIS Feature Service mutation responses.

  Validation is opt-in and does not change the response from `ArcGIS.Feature.mutate/3`.

      ArcGIS.Feature.mutate(service, mutations)
      |> ArcGIS.Feature.MutationResult.validate()
  """

  @doc """
  Validates an response from a mutation request.

  Returns `{:ok, results}` unchanged on success and passes request errors through
  unchanged.

  Checks `addResults`, `updateResults`, and `deleteResults`, including nested
  `attachments` and `assetMaps`, using string keys. Returns
  `{:error, {:mutation_failed, results}}` with the entire original response if
  any failure is reported. Top-level `error` and `"success" => false` responses
  also count as failures. No entries or context are removed.

  Unsupported values in the response or inspected result groups return
  `{:error, {:unexpected_mutation_result, value}}`.

  Async acknowledgements containing `statusUrl` or `resultUrl` pass through as
  `{:ok, response}`; this does not confirm that the edits succeeded.
  Fetch the final result separately and pass it to this function.

  ## Examples

      iex> ArcGIS.Feature.MutationResult.validate({:ok, [%{"addResults" => [%{"success" => true}]}]})
      {:ok, [%{"addResults" => [%{"success" => true}]}]}

      iex> ArcGIS.Feature.MutationResult.validate({:ok, %{"deleteResults" => [%{"success" => false, "objectId" => 1}]}})
      {:error, {:mutation_failed, %{"deleteResults" => [%{"success" => false, "objectId" => 1}]}}}
  """
  @spec validate({:ok, results} | {:error, reason}) ::
          {:ok, results}
          | {:error, {:mutation_failed, results} | {:unexpected_mutation_result, term()} | reason}
        when results: term(), reason: term()
  def validate({:error, _reason} = error), do: error

  def validate({:ok, results}) do
    case failure_reason(results) do
      nil -> {:ok, results}
      :mutation_failed -> {:error, {:mutation_failed, results}}
      reason -> {:error, reason}
    end
  end

  defp failure_reason(results) when is_list(results),
    do: Enum.find_value(results, &failure_reason/1)

  defp failure_reason(%{"error" => _}), do: :mutation_failed
  defp failure_reason(%{"success" => false}), do: :mutation_failed

  defp failure_reason(result) when is_map(result) do
    Enum.find_value(
      ["addResults", "updateResults", "deleteResults", "attachments", "assetMaps"],
      fn key -> failure_reason(Map.get(result, key, [])) end
    )
  end

  defp failure_reason(result), do: {:unexpected_mutation_result, result}
end
