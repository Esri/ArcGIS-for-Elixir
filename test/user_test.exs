defmodule ArcGIS.Test.User do
  use ArcGIS.Test.Helper
  doctest ArcGIS.User

  test "Translates a map to a user struct" do
    Req.Test.stub(ArcGIS, fn conn ->
      Req.Test.json(conn, Helper.load_data("arcgis/user.json") |> Jason.decode!())
    end)

    assert ArcGIS.User.from_token(Fixtures.portal(), "fake_token") == {:ok, Fixtures.user()}
  end

  test "Confirm user privilege" do
    assert ArcGIS.User.can?(Fixtures.user(), "premium:user:spatialanalysis")
  end

  test "Confirm user lacks privilege" do
    refute ArcGIS.User.can?(Fixtures.user(), "fatulations:user:spatialanalysis")
  end
end
