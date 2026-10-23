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

defmodule ArcGIS.Test.MutationResult do
  use ArcGIS.Test.Helper
  doctest ArcGIS.Feature.MutationResult

  alias ArcGIS.Feature.MutationResult

  test "accepts successful layer results" do
    results = [
      %{
        "id" => 0,
        "addResults" => [%{"success" => true}],
        "updateResults" => [%{"success" => true}],
        "deleteResults" => [%{"success" => true}]
      },
      %{
        "id" => 1,
        "addResults" => [%{"success" => true}],
        "updateResults" => [%{"success" => true}],
        "deleteResults" => [%{"success" => true}]
      }
    ]

    assert {:ok, ^results} = MutationResult.validate({:ok, results})
  end

  test "preserves the entire response when an operation fails" do
    add = %{"success" => false, "objectId" => 1, "error" => %{"code" => 1000}}

    update = %{
      "success" => false,
      "objectId" => 2,
      "error" => %{"description" => "Update failed"}
    }

    delete = %{"success" => false, "objectId" => 3}

    result = %{
      "addResults" => [%{"success" => true}, add],
      "updateResults" => [update],
      "deleteResults" => [delete]
    }

    assert {:error, {:mutation_failed, ^result}} = MutationResult.validate({:ok, result})
  end

  test "preserves successful and failed layers in input order" do
    first = %{"success" => false, "objectId" => 1}
    last = %{"success" => false, "objectId" => 2}

    results = [
      %{"id" => 0, "addResults" => [%{"success" => true}]},
      %{"id" => 1, "updateResults" => [first]},
      %{"id" => 2, "deleteResults" => [last]}
    ]

    assert {:error, {:mutation_failed, ^results}} = MutationResult.validate({:ok, results})
  end

  test "accepts empty responses and omitted operations" do
    for result <- [
          [],
          %{},
          %{"id" => 0},
          %{"addResults" => [], "updateResults" => []}
        ] do
      assert {:ok, ^result} = MutationResult.validate({:ok, result})
    end
  end

  test "detects failures in each feature, attachment, and asset-map operation" do
    for operation <- ["addResults", "updateResults", "deleteResults"],
        group <- [nil, "attachments", "assetMaps"],
        not (group == "assetMaps" and operation == "deleteResults") do
      edits = %{operation => [%{"success" => true}, %{"success" => false}]}
      result = if group, do: %{group => edits}, else: edits
      result = Map.put(result, "id", 0)

      assert {:error, {:mutation_failed, ^result}} = MutationResult.validate({:ok, result})
    end
  end

  test "preserves successful nested results and unique identifiers" do
    result = %{
      "addResults" => [
        %{"success" => true, "objectId" => 2_422_078_912_310_289_094, "uniqueIds" => ["id"]}
      ],
      "attachments" => %{
        "addResults" => [%{"success" => true}],
        "updateResults" => [%{"success" => true}],
        "deleteResults" => [%{"success" => true}]
      },
      "assetMaps" => %{
        "addResults" => [%{"success" => true}],
        "updateResults" => [%{"success" => true}]
      }
    }

    assert {:ok, ^result} = MutationResult.validate({:ok, result})
  end

  test "reports top-level errors and summary failures across layers" do
    error = %{
      "error" => %{
        "code" => 400,
        "extendedCode" => -2_147_207_418,
        "message" => "Unable to complete operation.",
        "details" => ["Violated attribute constraint rule.", "Operation rolled back."]
      }
    }

    failure = %{"success" => false}
    assert {:error, {:mutation_failed, ^error}} = MutationResult.validate({:ok, error})
    assert {:error, {:mutation_failed, ^failure}} = MutationResult.validate({:ok, failure})

    assert {:error, {:mutation_failed, [^error, ^failure]}} =
             MutationResult.validate({:ok, [error, failure]})

    assert {:ok, %{"success" => true}} = MutationResult.validate({:ok, %{"success" => true}})
  end

  test "passes through async acknowledgements and result links unchanged" do
    for response <- [
          %{"statusUrl" => "https://example.com/jobs/1/status"},
          %{"status" => "COMPLETED", "resultUrl" => "https://example.com/results/1.json"}
        ] do
      assert {:ok, ^response} = MutationResult.validate({:ok, response})
    end
  end

  test "handles the documented constraint violation response" do
    failure = %{
      "objectId" => 2,
      "globalId" => "{B703ACAC-A1A8-4F49-BB19-1E684A67A265}",
      "success" => false,
      "error" => %{
        "code" => 1019,
        "extendedCode" => -2_147_207_418,
        "description" => "Violated attribute constraint rule. [Error No: -1, ]"
      }
    }

    result = %{
      "addResults" => [],
      "updateResults" => [
        failure,
        %{
          "objectId" => 1,
          "globalId" => "{2FACC38A-3E3E-43A5-A6EB-BC9075407EC8}",
          "success" => true
        }
      ],
      "deleteResults" => []
    }

    assert {:error, {:mutation_failed, ^result}} = MutationResult.validate({:ok, result})
  end

  test "passes request errors through unchanged" do
    for reason <- [:timeout, :econnrefused, %{"error" => %{"code" => 400}}] do
      error = {:error, reason}
      assert ^error = MutationResult.validate(error)
    end
  end

  test "reports unsupported response values without raising" do
    for value <- [nil, false, 42, "invalid", {:ok, %{}}],
        response <- [
          value,
          [value],
          %{"addResults" => value},
          %{"updateResults" => [value]},
          %{"attachments" => %{"deleteResults" => [value]}},
          %{"assetMaps" => value}
        ] do
      assert {:error, {:unexpected_mutation_result, ^value}} =
               MutationResult.validate({:ok, response})
    end
  end
end
