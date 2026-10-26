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

      iex> ArcGIS.Feature.MutationResult.validate({:ok, %{"addResults" => [%{"success" => true}]}})
      {:ok, %{adds: %{failures: [], failures?: false, successes: [%{"success" => true}]}, failures?: false}}

      iex> ArcGIS.Feature.MutationResult.validate({:ok, %{"deleteResults" => [%{"success" => false, "objectId" => 1}]}})
      {:error, %{deletes: %{failures: [%{"objectId" => 1, "success" => false}], failures?: true, successes: []}, failures?: true}}
  """
  @spec validate({:ok, results} | {:error, reason}) ::
          {:ok, results}
          | {:error, {:mutation_failed, results} | {:unexpected_mutation_result, term()} | reason}
        when results: term(), reason: term()
  def validate({:error, _reason} = error), do: error
  def validate({:ok, %{"error" => error}}), do: {:error, error}
  def validate({:ok, %{"success" => false}}), do: {:error, "Unknown errror"}

  def validate({:ok, results}) do
    if ArcGIS.AsyncJob.valid_response?(results) do
      {:ok, ArcGIS.AsyncJob.from_response(results)}
    else
      validate_results(results)
    end
  end

  def validate(_), do: {:error, "Unexpected mutation result"}

  @doc """
  Given a validated mutation result, this function traverses the validation and
  returns only the failed mutations.
  """
  def extract_errors(%{failures: false}), do: %{layers: %{}}

  def extract_errors(%{layers: layers}) do
    %{
      layers:
        Enum.reduce(layers, %{}, fn layer, acc ->
          result =
            Enum.reduce(layer, %{}, fn
              {_mutation, %{failures?: false}}, acc -> acc
              # TODO
              {mutation, %{failures: failures}}, acc -> Map.put(acc, mutation, failures)
            end)

          if Enum.empty?(result) do
            acc
          else
            Map.put(acc, layer, result)
          end
        end)
    }
  end

  defp validate_results(results) do
    case check_results(results) do
      %{failures?: false} = checked -> {:ok, checked}
      checked -> {:error, checked}
    end
  end

  defp check_results(results) when is_list(results) do
    case results do
      [] ->
        %{successes: [], failures?: false, failures: []}

      [%{} | _] ->
        Enum.reduce(results, %{failures?: false, layers: %{}}, &check_layer_features/2)

      features when is_list(features) ->
        check_features(features)

      _ ->
        %{failures?: false, layers: {}}
    end
  end

  defp check_results(result) when is_map(result) do
    checked = check_mutation_map(result)

    Enum.reduce(
      [{"attachments", :attachments}, {"assetMaps", :asset_maps}],
      checked,
      fn {mutation_type, result_key}, acc ->
        case check_mutation_map(Map.get(result, mutation_type, [])) do
          nil ->
            acc

          checked ->
            acc
            |> Map.put(result_key, checked)
            |> Map.put(:failures?, acc.failures? or checked.failures?)
        end
      end
    )
  end

  defp check_results(_result), do: %{failures?: true}

  defp check_mutation_map(result) when is_map(result) do
    Enum.reduce(
      [
        {"addResults", :adds},
        {"updateResults", :updates},
        {"deleteResults", :deletes}
      ],
      %{failures?: false},
      fn {mutation_type, result_key}, acc ->
        Map.get(result, mutation_type, [])
        |> check_one_result_set(result_key, acc)
      end
    )
  end

  defp check_mutation_map(_), do: nil

  defp check_features([]), do: %{successes: [], failures?: false, failures: []}

  defp check_features(features) when is_list(features) do
    checked =
      Enum.reduce(
        features,
        %{successes: [], failures: []},
        &check_feature/2
      )

    Map.put(checked, :failures?, not Enum.empty?(checked.failures))
  end

  defp check_features(_), do: %{successes: [], failures?: false, failures: []}

  defp check_one_result_set([], _result_key, acc), do: acc

  defp check_one_result_set(features, result_key, acc) do
    checked = check_features(features)

    acc
    |> Map.put(result_key, checked)
    |> Map.put(:failures?, acc.failures? or checked.failures?)
  end

  defp check_layer_features(%{"id" => layer_id} = layer_results, acc) do
    results = check_results(layer_results)

    acc
    |> Map.put(:layers, Map.put(acc.layers, layer_id, results))
    |> Map.put(:failures?, acc.failures? or results.failures?)
  end

  defp check_feature(feature, acc) when is_map(feature) do
    case feature do
      %{"error" => _} ->
        Map.update!(acc, :failures, fn failures -> [feature | failures] end)

      %{"success" => false} ->
        Map.update!(acc, :failures, fn failures -> [feature | failures] end)

      _ ->
        Map.update!(acc, :successes, fn successes -> [feature | successes] end)
    end
  end

  defp check_feature(_, acc), do: acc
end
