defmodule ArcGIS.Test.Fixtures do
  @moduledoc false

  def test_json(name, scope \\ :arcgis) do
    name
    |> test_data(scope)
    |> JSON.decode!()
  end

  def test_data(name, scope \\ :arcgis) do
    name
    |> test_data_path(scope)
    |> File.read!()
  end

  def test_data_path(name, :arcgis) do
    Path.join("test/data/arcgis", name)
  end

  def test_data_path(name, _) do
    Path.join("test/data", name)
  end

  def portal(which \\ :base)

  def portal(:base) do
    {:ok, portal} = ArcGIS.Portal.new("https://arcgis.com")
    portal
  end

  def portal(:discovered) do
    portal(:base)
    |> Map.merge(%{
      type: :online,
      version: {2026, 3},
      help_url: URI.new!("https://doc.arcgis.com/en/arcgis-online/"),
      cdn_url: URI.new!("https://cdn.arcgis.com"),
      helper_services: %{
        "closestFacility" => %ArcGIS.Portal.HelperService{
          auxiliary: [],
          parameters: %{"defaultTravelMode" => "FEgifRtFndKNcJMJ"},
          url: %URI{
            scheme: "https",
            userinfo: nil,
            host: "route.arcgis.com",
            port: 443,
            path: "/arcgis/rest/services/World/ClosestFacility/NAServer/ClosestFacility_World",
            query: nil,
            fragment: nil
          }
        },
        "defaultElevationLayers" => %ArcGIS.Portal.HelperService{
          auxiliary: [
            %{
              url: %URI{
                scheme: "https",
                userinfo: nil,
                host: "elevation3d.arcgis.com",
                port: 443,
                path: "/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServerFeet",
                query: nil,
                fragment: nil
              },
              parameters: %{
                "id" => "auxiliaryElevation",
                "layerType" => "ArcGISTiledElevationServiceLayer",
                "units" => "esriFeet"
              }
            }
          ],
          parameters: %{
            "id" => "globalElevation",
            "layerType" => "ArcGISTiledElevationServiceLayer",
            "units" => "esriMeters"
          },
          url: %URI{
            scheme: "https",
            userinfo: nil,
            host: "elevation3d.arcgis.com",
            port: 443,
            path: "/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer",
            query: nil,
            fragment: nil
          }
        },
        "elevation" => %ArcGIS.Portal.HelperService{
          auxiliary: [],
          parameters: %{},
          url: %URI{
            scheme: "https",
            userinfo: nil,
            host: "elevation.arcgis.com",
            port: 443,
            path: "/arcgis/rest/services/Tools/Elevation/GPServer",
            query: nil,
            fragment: nil
          }
        },
        "geocode" => %ArcGIS.Portal.HelperService{
          auxiliary: [],
          parameters: %{
            "batch" => true,
            "eastLon" => "Xmax",
            "name" => "ArcGIS World Geocoding Service",
            "northLat" => "Ymax",
            "placefinding" => true,
            "southLat" => "Ymin",
            "suggest" => true,
            "westLon" => "Xmin"
          },
          url: %URI{
            scheme: "https",
            userinfo: nil,
            host: "geocode.arcgis.com",
            port: 443,
            path: "/arcgis/rest/services/World/GeocodeServer",
            query: nil,
            fragment: nil
          }
        },
        "traffic" => %ArcGIS.Portal.HelperService{
          auxiliary: [],
          parameters: %{},
          url: %URI{
            scheme: "https",
            userinfo: nil,
            host: "traffic.arcgis.com",
            port: 443,
            path: "/arcgis/rest/services/World/Traffic/MapServer",
            query: nil,
            fragment: nil
          }
        }
      }
    })
  end

  def feature_service(which \\ :default)

  def feature_service(:default) do
    %ArcGIS.Feature.Service{
      id: "test-feature-service",
      portal: portal(:discovered)
    }
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
