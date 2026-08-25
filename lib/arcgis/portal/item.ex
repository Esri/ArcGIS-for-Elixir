# Copyright 2025 Esri
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

 defmodule ArcGIS.Portal.Item do
  @moduledoc """
  Provides a struct for ArcGIS portal items and means to fetch and query them.
  """

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
    :folder,
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
          folder: String.t() | nil,
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
          owner: String.t(),
          title: String.t()
        }

  @spec query(Portal.t(), portal_item_search_terms, options :: [Portal.portal_option()]) ::
          {:ok, ArcGIS.Portal.ResultSet.t()} | {:error, reason :: String.t()}
  @doc "Queries an ArcGIS portal for one or more items"
  def query(%Portal{} = portal, search_terms, options \\ []) do
    query =
      []
      |> add_portal_item_search_keywords(search_terms)
      |> add_portal_item_search_text(search_terms)
      |> add_portal_item_type(search_terms)
      |> add_portal_item_owner(search_terms)
      |> add_portal_item_title(search_terms)
      |> Enum.join(" AND ")

    all_options =
      options
      |> Keyword.merge(
        is_features_query?: false,
        params: %{
          filter: query,
          num: Keyword.get(options, :limit, 100),
          start: Keyword.get(options, :offset, 1)
        },
        transform: &__MODULE__.from_map/1
      )

    Portal.get(portal, "/search", all_options)
  end

  @spec get(Portal.t(), id :: String.t(), options :: [Portal.portal_option()]) ::
          {:ok, t()} | {:error, reason :: String.t()}
  @doc "Fetches an item from an ArcGIS portal by global id"
  def get(%Portal{} = portal, id, options \\ []) when is_binary(id) do
    all_options =
      options
      |> Keyword.delete(:selector)
      |> Keyword.merge(
        is_features_query?: false,
        transform: &__MODULE__.from_map/1
      )

    Portal.get(portal, "/content/items/#{id}", all_options)
  end

  @spec create(Portal.t(), t(), options :: [Portal.portal_option()]) ::
          {:ok, t()} | {:error, reason :: String.t()}
  def create(%Portal{} = portal, %__MODULE__{} = item, options) do
    # TODO: support file uploads
    # item.accesas => requires a second call?
    owner = owner(portal, options)
    folder = if item.folder == nil, do: nil, else: "/#{item.folder}"
    resource = "/content/users/#{owner}#{folder}/addItem"

    form_data = as_create_form_data(item)

    # options = Keyword.put(options, :transform, &__MODULE__.from_map/1)
    create_options = Keyword.put(options, :selector, ["id"])

    case Portal.post(portal, resource, form_data, create_options) do
      {:ok, id} ->
        get(portal, id, options)

      error ->
        error
    end
  end

  @type deletion_results :: %{
          deletions: [String.t()],
          failures: [{id :: String.t(), reason :: String.t()}]
        }
  @spec delete(Portal.t(), t() | [t()], options :: [Portal.portal_option()]) :: deletion_results
  @doc "Deletes one or more portal items"
  def delete(%Portal{} = portal, %__MODULE__{} = item, options) do
    delete(portal, [item], options)
  end

  def delete(%Portal{} = portal, items, options) when is_list(items) do
    {deletions, _} =
      Enum.reduce(
        items,
        {%{}, nil},
        fn %{id: id, owner: owner}, {deletions, default_user} ->
          {user, new_default_user} =
            cond do
              owner != nil ->
                {owner, default_user}

              default_user != nil ->
                {default_user, default_user}

              true ->
                {:ok, token_user} =
                  ArcGIS.User.from_token(portal, Keyword.get(options, :auth_token))

                {token_user, token_user}
            end

          {Map.update(deletions, user, [id], fn ids -> [id | ids] end), new_default_user}
        end
      )

    Enum.reduce(deletions, %{deletions: [], failures: []}, fn batch, results ->
      delete_batch(batch, portal, options, results)
    end)
  end

  @spec delete_batch(
          {user_id :: String.t(), item_ids :: [map]},
          portal :: Portal.t(),
          options :: [Portal.portal_option()],
          deletion_results
        ) :: deletion_results
  defp delete_batch({user, item_ids}, portal, options, results) do
    resource = "/content/users/#{user}/deleteItems"
    # no body is used in this POST call
    form_data = %{}
    params = %{items: Enum.join(item_ids, ",")}
    delete_options = Keyword.merge(options, params: params, selector: ["results"])

    case Portal.post(portal, resource, form_data, delete_options) do
      {:ok, body} ->
        Enum.reduce(
          body,
          results,
          &add_item_deletion_to_results/2
        )

      error ->
        failures =
          Enum.reduce(item_ids, results.failures, fn id, failures -> [{id, error} | failures] end)

        %{results | failures: failures}
    end
  end

  defp add_item_deletion_to_results(%{"itemId" => id} = item, results) do
    if Map.get(item, "success", false) do
      %{results | deletions: [id | results.deletions]}
    else
      error =
        case Kernel.get_in(item, ["error", "message"]) do
          nil -> "Unknown"
          error -> error
        end

      %{results | failures: [{id, error} | results.failures]}
    end
  end

  @spec update(Portal.t(), t() | [t()], [Portal.portal_option()]) :: %{
          updates: [id :: String.t()],
          failures: [{id :: String.t(), reason :: String.t()}]
        }
  def update(%Portal{} = portal, %__MODULE__{} = item, options) do
    update(portal, [item], options)
  end

  def update(%Portal{} = portal, items, options) when is_list(items) do
    resource = "/content/updateItems"
    updates = Enum.map(items, fn item -> %{item.id => update_fields(item)} end)
    params = %{items: :json.encode(updates)}
    form_data = %{}
    update_options = Keyword.merge(options, params: params, selector: ["results"])

    case Portal.post(portal, resource, form_data, update_options) do
      {:ok, results} ->
        Enum.reduce(
          results,
          %{updates: [], failures: []},
          fn
            %{"itemId" => id, "success" => true}, acc ->
              %{acc | updates: [id | acc.updates]}

            %{"itemId" => id} = result, acc ->
              %{acc | failures: [{id, result["error"]} | acc.failures]}
          end
        )

      error ->
        error
    end
  end

  @spec share(
          Portal.t(),
          t(),
          share_with :: :everyone | :org | :private | (groups :: [String.t()]),
          [Portal.portal_option()]
        ) :: {:ok, t()} | {:error, reason :: String.t()}
  def share(%Portal{} = portal, %__MODULE__{id: item_id} = item, share_with, options) do
    resource = "/content/users/#{item.owner}/items/#{item_id}/share"

    params =
      case share_with do
        :private -> %{groups: ""}
        :everyone -> %{account: true, everyone: true}
        :org -> %{org: true}
        groups when is_list(groups) -> %{groups: Enum.join(groups, ",")}
      end

    form_data = %{}
    update_options = Keyword.merge(options, params: params)

    case Portal.post(portal, resource, form_data, update_options) do
      {:ok, %{"itemId" => ^item_id, "notSharedWith" => []}} ->
        {:ok, item}

      {:ok, %{"itemId" => ^item_id, "notSharedWith" => unshared}} ->
        {:error, "Could not share with: #{Enum.join(unshared, ",")}"}

      error ->
        error
    end
  end

  defp update_fields(item) do
    %{
      accessInformation: item.accessInformation,
      categories: item.categories,
      culture: item.culture,
      description: item.description,
      documentation: item.documentation,
      licenseInfo: item.licenseInfo,
      name: item.name,
      properties: item.properties,
      proxyFilter: item.proxyFilter,
      snippet: item.snippet,
      tags: item.tags,
      thumbnail: item.thumbnail,
      title: item.title,
      type: item.type,
      typeKeywords: item.type_keywords,
      url: item.url
    }
  end

  @spec from_map(map) :: t()
  @doc """
  Create an `%ArcGIS.Portal.Item{}` from a map.

  Used internally to transform maps of data returned by an ArcGIS portal
  into item structs.
  """
  def from_map(%{} = arcgis_map) do
    raw_wkid = lookup(arcgis_map, "spatialReference", 0)
    wkid = ArcGIS.Utils.to_integer(raw_wkid, raw_wkid)

    spatial_reference = %ArcGIS.SpatialReference{
      wkid: wkid
    }

    %__MODULE__{
      id: lookup(arcgis_map, "id", ""),
      access: String.to_existing_atom(lookup(arcgis_map, "access", "private")),
      accessInformation: lookup(arcgis_map, "accessInformation", ""),
      categories: lookup(arcgis_map, "categories", []),
      counts: counts_from_map(arcgis_map),
      culture: lookup(arcgis_map, "culture", []),
      description: lookup(arcgis_map, "description", ""),
      documentation: lookup(arcgis_map, "documentation", ""),
      extent: ArcGIS.Extent.new(Map.get(arcgis_map, "extent")),
      folder: lookup(arcgis_map, "ownerFolder", nil),
      licenseInfo: lookup(arcgis_map, "licenseInfo", ""),
      name: lookup(arcgis_map, "name", ""),
      owner: lookup(arcgis_map, "owner", ""),
      properties: lookup(arcgis_map, "properties", %{}),
      screenshots: lookup(arcgis_map, "screenshots", []),
      size: lookup(arcgis_map, "size", 0),
      snippet: lookup(arcgis_map, "snippet", ""),
      spatial_reference: spatial_reference,
      tags: lookup(arcgis_map, "tags", []),
      thumbnail: lookup(arcgis_map, "thumbnail", ""),
      timestamps: timestamps_from_map(arcgis_map),
      title: lookup(arcgis_map, "title", ""),
      type: lookup(arcgis_map, "type", ""),
      type_keywords: lookup(arcgis_map, "typeKeywords", []),
      url: lookup(arcgis_map, "url", "")
    }
  end

  defp owner(portal, options) do
    case Keyword.get(options, :owner) do
      nil -> user_from_token(portal, options)
      owner -> owner
    end
  end

  defp user_from_token(portal, options) do
    with token when is_binary(token) <- Keyword.get(options, :auth_token),
         {:ok, user} <- ArcGIS.User.from_token(portal, token) do
      user.name.user
    else
      _ -> nil
    end
  end

  defp as_create_form_data(item) do
    %{
      accessInformation: item.accessInformation,
      categories: :json.encode(item.categories),
      culture: item.culture,
      description: item.description,
      documentation: item.documentation,
      extent: form_data_extent(item.extent),
      licenseInfo: item.licenseInfo,
      name: item.name,
      properties: :json.encode(item.properties),
      proxyFilter: item.proxyFilter,
      snippet: item.snippet,
      spatialReference: ArcGIS.SpatialReference.best_srid(item.spatial_reference),
      tags: Enum.join(item.tags, ", "),
      thumbnail: item.thumbnail,
      title: item.title,
      type: item.type,
      type_keywords: Enum.join(item.type_keywords, ", "),
      url: item.url
    }
  end

  defp form_data_extent(extent) do
    if ArcGIS.Extent.empty?(extent) do
      nil
    else
      "#{Enum.join(extent.northwest.coordinates, ", ")}, #{Enum.join(extent.southeast.coordinates, ", ")}"
    end
  end

  defp lookup(map, key, default) do
    # || is used here, as if the map has the entry but it is
    # explicitly set to nil, Map.get/3 will return the nil value
    # rather than the default
    Map.get(map, key) || default
  end

  @spec counts_from_map(map) :: counts
  defp counts_from_map(map) do
    %{
      comments: lookup(map, "numComments", 0),
      ratings: lookup(map, "numRatings", 0),
      views: lookup(map, "numViews", 0)
    }
  end

  @spec timestamps_from_map(map) :: ArcGIS.Timestamps.t()
  defp timestamps_from_map(map) do
    %ArcGIS.Timestamps{
      created: lookup(map, "created", 0),
      last_access: lookup(map, "lastViewed", 0),
      modified: lookup(map, "modified", 0)
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

  defp add_portal_item_title(acc, search_terms) do
    case Map.get(search_terms, :title) do
      nil -> acc
      value -> ["title:\"#{value}\"" | acc]
    end
  end
end
