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

defmodule ArcGIS.Test.Feature do
  use ArcGIS.Test.Helper
  doctest ArcGIS.Portal

  test "query/3 constructds a valid query" do
    Req.Test.stub(
      ArcGIS,
      fn conn ->
        case ArcGIS.Test.Fixtures.Network.common_response(conn) do
          {:ok, response} ->
            response

          {_, conn} ->
            assert conn.request_path ==
                     "/arcgis/rest/services/66a0fa165d1649ce8048e64e3fb61504/FeatureServcer/0/query"

            assert Map.get(conn.params, "orderByFields") == "foo ASC, bar DESC, string, atom"
            assert Map.get(conn.params, "outFields") == "*"

            Req.Test.json(conn, ArcGIS.Test.Fixtures.Network.json("query_features"))
        end
      end
    )

    layer_id = 0

    query = [
      order_by: [{:foo, :asc}, {"bar", :desc}, "string", :atom]
    ]

    assert {:ok, _features} =
             ArcGIS.Feature.query(ArcGIS.Test.Fixtures.feature_service(), layer_id, query)
  end
end
