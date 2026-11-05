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

  describe "Item.patch/3" do
    alias ArcGIS.Portal.Item

    test "collects all validation errors before sending any requests" do
      Req.Test.stub(ArcGIS, fn _conn -> flunk("Invalid batch must not send requests") end)
      item = %Item{id: "invalid", owner: "owner"}

      updates = [
        {%{item | id: "valid"}, %{title: "Valid title"}},
        {item,
         %{
           title: 123,
           tags: ["valid", 123],
           categories: "invalid",
           type_keywords: nil,
           properties: [],
           unknown: "value"
         }},
        {%{item | id: "empty"}, %{}},
        {%{item | id: "not-map"}, nil}
      ]

      assert {:error, errors} = Item.patch(Fixtures.portal(), updates, [])

      assert Enum.sort(errors) ==
               Enum.sort([
                 {"invalid", "title must be a string"},
                 {"invalid", "tags must be a list of strings"},
                 {"invalid", "categories must be a list of strings"},
                 {"invalid", "type_keywords must be a list of strings"},
                 {"invalid", "properties must be a map"},
                 {"invalid", "Unsupported change field: :unknown"},
                 {"empty", "Changes are empty"},
                 {"not-map", "Changes must be a map"}
               ])
    end

    test "accepts valid scalar, list, and map changes" do
      Req.Test.stub(ArcGIS, fn conn ->
        assert conn.request_path == "/sharing/rest/content/users/owner/items/item-id/update"
        Req.Test.json(conn, %{"id" => "item-id", "success" => true})
      end)

      item = %Item{id: "item-id", owner: "owner"}

      changes = %{
        title: "",
        tags: [],
        type_keywords: ["Service"],
        properties: %{},
        categories: []
      }

      assert Item.patch(Fixtures.portal(), {item, changes}, []) ==
               {:ok, %{updates: ["item-id"], failures: []}}
    end

    test "accepts empty category lists through the batch endpoint" do
      Req.Test.stub(ArcGIS, fn conn ->
        assert conn.request_path == "/sharing/rest/content/updateItems"
        Req.Test.json(conn, %{"results" => [%{"itemId" => "item-id", "success" => true}]})
      end)

      assert Item.patch(Fixtures.portal(), {%Item{id: "item-id"}, %{categories: []}}, []) ==
               {:ok, %{updates: ["item-id"], failures: []}}
    end

    test "returns request errors with results accumulated before failure" do
      Req.Test.stub(ArcGIS, fn conn ->
        case conn.params["title"] do
          "Earlier update" ->
            Req.Test.json(conn, %{"id" => "first-item", "success" => true})

          "Failing update" ->
            conn
            |> Plug.Conn.put_status(503)
            |> Req.Test.json(%{"error" => %{"message" => "Unavailable"}})
        end
      end)

      first_item = %Item{id: "first-item", owner: "owner"}
      second_item = %Item{id: "second-item", owner: "owner"}

      assert {:error, %{reason: "Unavailable", results: results}} =
               Item.patch(
                 Fixtures.portal(),
                 [
                   {first_item, %{title: "Earlier update"}},
                   {second_item, %{title: "Failing update"}}
                 ],
                 []
               )

      assert results == %{updates: ["first-item"], failures: []}
    end
  end
end
