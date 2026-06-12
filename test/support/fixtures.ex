defmodule ArcGIS.Test.Fixtures do
  @moduledoc false

  def portal(which \\ :base)

  def portal(:base) do
    ArcGIS.Portal.new("https://arcgis.com")
  end

  def portal(:discovered) do
    portal(:base)
    |> Map.put(:type, :online)
    |> Map.put(:version, {2025, 3})
    |> Map.put(:help_url, URI.new!("https://doc.arcgis.com/en/arcgis-online/"))
  end

  def user do
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
        full: "Spherical Cow",
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
end
