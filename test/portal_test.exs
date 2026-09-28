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
end
