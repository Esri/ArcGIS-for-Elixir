defmodule ArcGIS.Portal.Item do
  alias ArcGIS.Portal

  # not include:
  #   advancedSettings: undocumented
  # apiToken[12]ExpirationDate: undocumented
  # appCategories: undocumented
  # avgRating: undocumented
  # banner: undocumented
  # classification: undocumented
  # groupDesignations: undocumented
  # guid: undocumented
  # industries: undocumented
  # languages: undocumented
  # largeThumbnail: is this used?
  # listed: undocumented
  # subInfo: undocumented
  # scoreCompleteness: undocumented
  # proxyFilter: undocumented

  defstruct [
    :id,
    :access,
    :accessInformation,
    :categories,
    :culture,
    :description,
    :documentation,
    :extent,
    :licenseInfo,
    :name,
    :counts,
    :owner,
    :properties,
    :proxyFilter,
    :scoreCompleteness,
    :screenshots,
    :size,
    :snippet,
    :spatial_reference,
    :tags,
    :thumbnail,
    :timestamps,
    :title,
    :type,
    :type_keywords,
    :url
  ]

  @type access :: :private | :shared | :org | :public
  @type counts :: %{comments: non_neg_integer, ratings: non_neg_integer, views: non_neg_integer}
  @type t :: %__MODULE__{
          id: Portal.id(),
          access: access,
          accessInformation: String.t(),
          categories: [String.t()],
          counts: counts,
          culture: String.t(),
          description: String.t(),
          documentation: String.t(),
          extent: ArcGIS.Extent.t(),
          licenseInfo: String.t(),
          name: String.t(),
          owner: String.t(),
          properties: map,
          screenshots: [String.t()],
          size: integer,
          snippet: String.t(),
          spatial_reference: ArcGIS.SpatialReference.t(),
          tags: [String.t()],
          thumbnail: String.t(),
          timestamps: ArcGIS.Timestamps.t(),
          title: String.t(),
          type: String.t(),
          type_keywords: [String.t()],
          url: String.t()
        }

  @type portal_item_search_terms :: %{
          search_text: String.t(),
          keywords: [{key :: String.t(), value :: String.t()}],
          type: type :: String.t() | {type :: String.t(), keywords :: String.t()},
          owner: String.t()
        }

  @spec query(Portal.t(), portal_item_search_terms, options :: [Portal.portal_option()]) ::
          {:ok, map} | {:error, reason :: String.t()}
  def query(%Portal{} = portal, search_terms, options \\ []) do
    query =
      []
      |> add_portal_item_search_keywords(search_terms)
      |> add_portal_item_search_text(search_terms)
      |> add_portal_item_type(search_terms)
      |> add_portal_item_owner(search_terms)
      |> Enum.join(" AND ")

    all_options =
      options
      |> Keyword.put(:is_features_query?, false)
      |> Keyword.put(:params, %{q: query})
      |> Keyword.put(:transform, &new/1)

    Portal.get(portal, "/search", all_options)
  end

  @spec get(Portal.t(), id :: String.t(), options :: [Portal.portal_option()]) ::
          {:ok, map} | {:error, reason :: String.t()}
  def get(%Portal{} = portal, id, options \\ []) when is_binary(id) do
    Portal.get(portal, "/content/items/#{id}", options)
  end

  @spec new(map) :: t()
  def new(%{} = arcgis_map) do
    spatial_reference = %ArcGIS.SpatialReference{
      wkid: from_map(arcgis_map, "spatialReference", 0)
    }

    %__MODULE__{
      id: from_map(arcgis_map, "id", ""),
      access: String.to_existing_atom(from_map(arcgis_map, "access", "private")),
      accessInformation: from_map(arcgis_map, "accessInformation", ""),
      categories: from_map(arcgis_map, "categories", []),
      counts: counts_from_map(arcgis_map),
      culture: from_map(arcgis_map, "culture", []),
      description: from_map(arcgis_map, "description", ""),
      documentation: from_map(arcgis_map, "documentation", ""),
      extent: ArcGIS.Extent.new(Map.get(arcgis_map, "extent")),
      licenseInfo: from_map(arcgis_map, "", ""),
      name: from_map(arcgis_map, "name", ""),
      owner: from_map(arcgis_map, "owner", ""),
      properties: from_map(arcgis_map, "properties", %{}),
      screenshots: [from_map(arcgis_map, "screenshots", [])],
      size: from_map(arcgis_map, "size", 0),
      snippet: from_map(arcgis_map, "snippet", ""),
      spatial_reference: spatial_reference,
      tags: [from_map(arcgis_map, "tags", [])],
      thumbnail: from_map(arcgis_map, "thumbnail", ""),
      timestamps: timestamps_from_map(arcgis_map),
      title: from_map(arcgis_map, "title", ""),
      type: from_map(arcgis_map, "type", ""),
      type_keywords: [from_map(arcgis_map, "typeKeywords", "")],
      url: from_map(arcgis_map, "url", "")
    }
  end

  defp from_map(map, key, default) do
    # || is used here, as if the map has the entry but it is
    # explicitly set to nil, Map.get/3 will return the nil value
    # rather than the default
    Map.get(map, key) || default
  end

  @spec counts_from_map(map) :: counts
  defp counts_from_map(map) do
    %{
      comments: from_map(map, "numComments", 0),
      ratings: from_map(map, "numRatings", 0),
      views: from_map(map, "numViews", 0)
    }
  end

  @spec timestamps_from_map(map) :: ArcGIS.Timestamps.t()
  defp timestamps_from_map(map) do
    %ArcGIS.Timestamps{
      created: from_map(map, "created", 0),
      last_access: from_map(map, "lastViewed", 0),
      modified: from_map(map, "modified", 0)
    }
  end

  defp add_portal_item_search_keywords(acc, search_terms) do
    Map.get(search_terms, :keywords, [])
    |> Enum.reduce(acc, fn {key, value}, acc ->
      ["#{key}:\"#{value}\"" | acc]
    end)
  end

  defp add_portal_item_search_text(acc, search_terms) do
    case Map.get(search_terms, :search_text) do
      nil -> acc
      value -> [value | acc]
    end
  end

  defp add_portal_item_type(acc, search_terms) do
    case Map.get(search_terms, :type) do
      nil -> acc
      {type, keywords} -> ["type:\"#{type}\"", "typekeywords:\"#{keywords}\"" | acc]
      type -> ["type:\"#{type}\"" | acc]
    end
  end

  defp add_portal_item_owner(acc, search_terms) do
    case Map.get(search_terms, :owner) do
      nil -> acc
      value -> ["owner:#{value}" | acc]
    end
  end
end
