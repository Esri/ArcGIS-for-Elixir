defmodule ArcGIS.Test.Portal do
  use ArcGIS.Test.Helper
  doctest ArcGIS.Portal

  test "discover/1 returns a %Portal{} with full information" do
    Req.Test.stub(ArcGIS, fn conn ->
      assert(conn.request_path == "/sharing/rest/portals/self")
      Req.Test.json(conn, Fixtures.Network.json("portal_self"))
    end)

    assert ArcGIS.Portal.discover(Fixtures.portal()) == {:ok, Fixtures.portal(:discovered)}
  end
end
