# Copyright 2025 Esri
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

defmodule ArcGISTest do
  use ExUnit.Case
  doctest ArcGIS

  test "check_for_error/2 returns the original term on error" do
    [
      {:error, "Error"},
      {:ok, %Req.Response{body: %{}}},
      {:ok, %Req.Response{body: %{"error" => %{}}}},
      {:ok, %Req.Response{status: 100, body: %{"something" => "yes"}}},
      {:ok, %Req.Response{status: 300, body: %{"something" => "yes"}}}
    ]
    |> Enum.each(fn error ->
      assert(ArcGIS.check_for_error(error) === error)
    end)
  end

  test "check_for_error/2 returns the :noerror on non-error" do
    [
      {:ok, :ok},
      {:ok, %Req.Response{status: 200, body: %{"something" => "yes"}}}
    ]
    |> Enum.each(fn error ->
      assert(ArcGIS.check_for_error(error) === :noerror)
    end)
  end
end
