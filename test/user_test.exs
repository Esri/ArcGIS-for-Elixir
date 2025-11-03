defmodule ArcGIS.Test.User do
  use ArcGIS.Test.Helper
  doctest ArcGIS.User

  def expected_user do
    %ArcGIS.User{
      access: "org",
      culture: %ArcGIS.User.Culture{
        code: "en-CA",
        format: "ca",
        units: "english"
      },
      description: nil,
      email: "user@test.com",
      groups: [],
      id: "ad61b33cde1b4be285b8bdaba90a589d",
      license: nil,
      name: %{
        first: "Spherical",
        full: "Aaron Seigo",
        last: "Cow",
        user: "test_user"
      },
      org_id: "r0I0JMe21LRdkKyK",
      privileges: [
        "features:user:edit",
        "portal:publisher:publishFeatures",
        "portal:publisher:publishScenes",
        "portal:publisher:publishTiles",
        "portal:user:addExternalMembersToGroup",
        "portal:user:createGroup",
        "portal:user:createItem",
        "portal:user:joinGroup",
        "portal:user:joinNonOrgGroup",
        "portal:user:shareGroupToOrg",
        "portal:user:shareGroupToPublic",
        "portal:user:shareToGroup",
        "portal:user:shareToOrg",
        "portal:user:shareToPublic",
        "portal:user:viewOrgGroups",
        "portal:user:viewOrgItems",
        "portal:user:viewOrgUsers",
        "premium:publisher:createAdvancedNotebooks",
        "premium:publisher:createNotebooks",
        "premium:publisher:rasteranalysis",
        "premium:user:basemaps",
        "premium:user:demographics",
        "premium:user:featurereport",
        "premium:user:geocode",
        "premium:user:geocode:stored",
        "premium:user:geocode:temporary",
        "premium:user:geoenrichment",
        "premium:user:networkanalysis",
        "premium:user:networkanalysis:closestfacility",
        "premium:user:networkanalysis:lastmiledelivery",
        "premium:user:networkanalysis:locationallocation",
        "premium:user:networkanalysis:optimizedrouting",
        "premium:user:networkanalysis:origindestinationcostmatrix",
        "premium:user:networkanalysis:routing",
        "premium:user:networkanalysis:servicearea",
        "premium:user:networkanalysis:snaptoroads",
        "premium:user:networkanalysis:vehiclerouting",
        "premium:user:places",
        "premium:user:spatialanalysis"
      ],
      provider: "arcgis",
      region: "US",
      role: %ArcGIS.User.Role{
        id: "vsa7oP1fZvDkRTT7",
        name: "org_publisher"
      },
      storage_usage: 294_423_245_635,
      tags: [],
      thumbnail: nil,
      timestamps: %ArcGIS.Timestamps{
        created: 1_591_125_967_000,
        last_access: 1_761_657_910_000,
        modified: 1_654_846_726_000
      },
      user_type: "arcgisonly"
    }
  end

  test "Translates a map to a user struct" do
    Req.Test.stub(ArcGIS, fn conn ->
      Req.Test.json(conn, Helper.load_data("arcgis/user.json") |> Jason.decode!())
    end)

    assert ArcGIS.User.from_token(Fixtures.portal(), "fake_token") == {:ok, expected_user()}
  end

  test "Confirm user privilege" do
    assert ArcGIS.User.can?(expected_user(), "premium:user:spatialanalysis")
  end

  test "Confirm user lacks privilege" do
    refute ArcGIS.User.can?(expected_user(), "fatulations:user:spatialanalysis")
  end
end
