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

defmodule ArcGIS.Test.Portal do
  use ArcGIS.Test.Helper, async: true
  doctest ArcGIS.Portal

  describe "derfault_portal/1" do
    test "returns a default is nothing is configured" do
      Application.delete_env(:arcgis, :portal)
      assert %ArcGIS.Portal{} = ArcGIS.Portal.default_portal()
    end

    test "returns the configured portal" do
      Application.put_env(:arcgis, :portal, %ArcGIS.Portal{
        base_url: URI.parse("https://example.com"),
        type: :custom
      })

      assert %ArcGIS.Portal{base_url: %URI{host: "example.com"}, type: :custom} =
               ArcGIS.Portal.default_portal()
    end
  end

  test "discover/1 returns a %Portal{} with full information" do
    Req.Test.stub(ArcGIS, fn conn ->
      assert(conn.request_path == "/sharing/rest/portals/self")
      Req.Test.json(conn, Fixtures.Network.json("portal_self"))
    end)

    assert ArcGIS.Portal.discover(Fixtures.portal()) == {:ok, Fixtures.portal(:discovered)}
  end

  describe "item/get" do
    test "An item deserializes properly" do
      Req.Test.stub(
        ArcGIS,
        fn conn ->
          {:ok, response} = ArcGIS.Test.Fixtures.Network.common_response(conn)
          response
        end
      )

      assert {:ok,
              %ArcGIS.Portal.Item{
                id: "66a0fa165d1649ce8048e64e3fb61504",
                title: "Testing Async",
                spatial_reference: %ArcGIS.SpatialReference{wkid: 102_100},
                proxyFilter: nil,
                scoreCompleteness: 16
              }} = ArcGIS.Portal.Item.get(Fixtures.portal(), "test-feature-service")
    end
  end

  describe "item/update" do
    test "An item serializes properly and passes the Req's encoder" do
      Req.Test.stub(
        ArcGIS,
        fn conn ->
          case ArcGIS.Test.Fixtures.Network.common_response(conn) do
            {:ok, response} ->
              response

            {:no_common_match, conn} ->
              assert conn.method == "POST"

              assert conn.request_path ==
                       "/sharing/rest/content/users/urban_aaron_dev/items/66a0fa165d1649ce8048e64e3fb61504/update"

              assert conn.body_params["spatialReference"] == "102100"
              assert conn.body_params["typeKeywords"] == "Urban,Urban-Model"
              refute Map.has_key?(conn.body_params, "serviceProxyFilter")
              assert conn.body_params["url"] == ""
              assert conn.query_params["clearEmptyFields"] == "true"

              assert conn.body_params["extent"] ==
                       "5.952605381842136, 45.82037021294237, 10.49172963042796, 47.81009886898107"

              refute Map.has_key?(conn.body_params, "type")
              refute Map.has_key?(conn.body_params, "counts")
              refute Map.has_key?(conn.body_params, "timestamps")

              Req.Test.json(conn, %{
                "id" => "66a0fa165d1649ce8048e64e3fb61504",
                "success" => true
              })
          end
        end
      )

      {:ok, item} = ArcGIS.Portal.Item.get(Fixtures.portal(), "test-feature-service")
      item = %{item | url: nil}

      assert ArcGIS.Portal.Item.update(Fixtures.portal(), item, params: %{clearEmptyFields: true}) ==
               %{failures: [], updates: ["66a0fa165d1649ce8048e64e3fb61504"]}
    end
  end
end
