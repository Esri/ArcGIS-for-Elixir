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

defmodule ArcGIS.Portal.Item do
  @moduledoc """
  Provides a struct for ArcGIS portal items and functions to query, fetch,
  create, update, delete, and share them.
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

  @typedoc """
  Explicit item changes. Omitted fields are left unchanged.

  Tags, categories, and type keywords are lists of strings; properties is a map.
  Extent, spatial reference, and file uploads are not supported.
  """
  @type changes :: %{
          optional(:title) => String.t(),
          optional(:thumbnailUrl) => String.t(),
          optional(:type_keywords) => [String.t()],
          optional(:description) => String.t(),
          optional(:tags) => [String.t()],
          optional(:snippet) => String.t(),
          optional(:accessInformation) => String.t(),
          optional(:licenseInfo) => String.t(),
          optional(:culture) => String.t(),
          optional(:properties) => map(),
          optional(:url) => String.t(),
          optional(:serviceUsername) => String.t(),
          optional(:servicePassword) => String.t(),
          optional(:categories) => [String.t()],
          optional(:text) => String.t(),
          optional(:dataUrl) => String.t()
        }

  @typedoc "An item and its explicit changes."
  @type item_patch :: {t(), changes()}

  @typedoc "Item IDs successfully updated and individual update failures."
  @type patch_results :: %{
          updates: [String.t()],
          failures: [{String.t(), String.t()}]
        }

  @typedoc "A request failure and the results accumulated before it occurred."
  @type patch_request_error :: %{reason: String.t(), results: patch_results()}

  @typedoc "Validation errors, request failures with partial results, or request error strings."
  @type patch_error ::
          validation_errors() | patch_request_error() | String.t()

  @typedoc "Validation errors associated with item IDs."
  @type validation_errors :: [{item_id :: String.t(), reason :: String.t()}]

  @supported_patch_fields ~w(
    title thumbnailUrl type_keywords description tags snippet
    accessInformation licenseInfo culture properties url
    serviceUsername servicePassword categories text dataUrl
  )a

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

    case Portal.post(portal, resource, form_data, options) do
      {:ok, %{"id" => id}} ->
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
    delete_options = Keyword.merge(options, params: params)

    case Portal.post(portal, resource, form_data, delete_options) do
      {:ok, %{"results" => batch_results}} ->
        Enum.reduce(
          batch_results,
          results,
          &add_item_deletion_to_results/2
        )

      {:error, error} ->
        add_errors(error, item_ids, results)

      _ ->
        add_errors("Query failed", item_ids, results)
    end
  end

  defp add_errors(error, item_ids, results) do
    failures =
      Enum.reduce(item_ids, results.failures, fn id, failures -> [{id, error} | failures] end)

    %{results | failures: failures}
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

  @spec patch(Portal.t(), item_patch() | [item_patch()], Portal.portal_options()) ::
          {:ok, patch_results()}
          | {:error, patch_error()}

  @doc """
  Patches an existing Portal Item.

  Accepts `{item, changes}` or a list of such tuples. Only fields present in
  `changes` are sent; omitted fields are left unchanged.

  List fields such as categories, tags, and type keywords replace the existing
  lists rather than append to them. An empty list clears the corresponding
  field.

  The library does not merge changes with existing item values. Structured
  fields such as `properties` are passed to ArcGIS, whose update semantics
  apply.

  All changes maps are validated before any requests are sent. Invalid input
  returns `{:error, [{item_id, reason}]}`, with one entry per validation error.

  Updates items sequentially unless every item’s changes contain only `:categories`,
  in which case a single bulk update request is sent.

  A sequential request failure stops processing and returns the request reason
  with the results accumulated so far. A bulk request failure returns its reason.

  ## Examples

      Item.patch(portal, {item, %{title: "New title"}}, options)

      Item.patch(portal, [
        {item_a, %{categories: ["/Categories/Planning"]}},
        {item_b, %{categories: []}}
      ], options)
  """
  def patch(%Portal{} = portal, {%__MODULE__{}, _} = update, options) do
    patch(portal, [update], options)
  end

  def patch(%Portal{}, [], _options), do: {:ok, %{updates: [], failures: []}}

  def patch(%Portal{} = portal, updates, options) when is_list(updates) do
    case validate_patches(updates) do
      [] ->
        if Enum.all?(updates, fn {_item, changes} -> Map.keys(changes) == [:categories] end) do
          patch_categories(portal, updates, options)
        else
          patch_items_sequentially(portal, updates, options)
        end

      errors ->
        {:error, errors}
    end
  end

  @spec update(Portal.t(), t() | [t()], [Portal.portal_option()]) :: %{
          updates: [id :: String.t()],
          failures: [{id :: String.t(), reason :: String.t()}]
        }
  @doc """
  Updates whole items. Prefer patch/3 with explicit changes. Fields with `nil`
  values are sent as empty form field values, not omitted. ArcGIS determines how
  those empty values are applied.
  """
  @deprecated "Use patch/3 with explicit changes instead"
  def update(%Portal{} = portal, %__MODULE__{} = item, options) do
    update(portal, [item], options)
  end

  def update(%Portal{} = portal, items, options) when is_list(items) do
    Enum.reduce(items, %{updates: [], failures: []}, fn item, acc ->
      case update_item(portal, item, options) do
        :ok ->
          %{acc | updates: [item.id | acc.updates]}

        {:error, reason} ->
          %{acc | failures: [{item.id, reason} | acc.failures]}
      end
    end)
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

  defp validate_patches(updates) do
    Enum.flat_map(updates, fn {item, changes} ->
      Enum.map(validate_changes(changes), fn reason -> {item.id, reason} end)
    end)
  end

  defp validate_changes(changes) when not is_map(changes),
    do: ["Changes must be a map"]

  defp validate_changes(changes) when map_size(changes) == 0,
    do: ["Changes are empty"]

  defp validate_changes(changes) do
    Enum.flat_map(changes, fn {key, value} ->
      case validate_change(key, value) do
        :ok -> []
        {:error, reason} -> [reason]
      end
    end)
  end

  defp validate_change(key, value) when key in [:categories, :type_keywords, :tags] do
    case is_list(value) and Enum.all?(value, &is_binary/1) do
      true -> :ok
      false -> {:error, "#{key} must be a list of strings"}
    end
  end

  defp validate_change(:properties, value) do
    case is_map(value) do
      true -> :ok
      false -> {:error, "properties must be a map"}
    end
  end

  defp validate_change(key, value) when key in @supported_patch_fields do
    case is_binary(value) do
      true -> :ok
      false -> {:error, "#{key} must be a string"}
    end
  end

  defp validate_change(key, _value),
    do: {:error, "Unsupported change field: #{inspect(key)}"}

  defp patch_categories(portal, updates, options) when is_list(updates) do
    resource = "/content/updateItems"

    payload =
      Enum.map(updates, fn {item, changes} ->
        %{item.id => %{categories: changes.categories}}
      end)

    params = %{items: payload |> :json.encode() |> IO.iodata_to_binary()}
    form_data = %{}
    update_options = Keyword.merge(options, params: params)

    case Portal.post(portal, resource, form_data, update_options) do
      {:ok, %{"results" => results}} ->
        transformed_results =
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

        {:ok, transformed_results}

      {:error, reason} ->
        {:error, reason}

      response ->
        {:error, "Unexpected category update response: #{inspect(response)}"}
    end
  end

  defp patch_items_sequentially(portal, updates, options) do
    Enum.reduce_while(
      updates,
      {:ok, %{updates: [], failures: []}},
      fn {item, changes}, {:ok, results} ->
        case patch_item(portal, item, changes, options) do
          :ok ->
            results = %{results | updates: [item.id | results.updates]}
            {:cont, {:ok, results}}

          {:error, reason} ->
            {:halt, {:error, %{reason: reason, results: results}}}
        end
      end
    )
  end

  defp patch_item(portal, item, changes, options) do
    resource = "/content/users/#{item.owner}/items/#{item.id}/update"
    form_data = serialize_item_fields(changes)

    case Portal.post(portal, resource, form_data, options) do
      {:ok, %{"id" => id, "success" => true}} when id == item.id ->
        :ok

      {:error, reason} ->
        {:error, reason}

      response ->
        {:error, "Unexpected item update response: #{inspect(response)}"}
    end
  end

  defp update_item(portal, item, options) do
    patch_item(portal, item, update_fields(item), options)
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
      type_keywords: item.type_keywords,
      url: item.url
    }
  end

  defp serialize_item_fields(changes) do
    Map.new(changes, fn
      {:type_keywords, nil} ->
        {:typeKeywords, nil}

      {key, nil} ->
        {key, nil}

      {:type_keywords, values} ->
        {:typeKeywords, Enum.join(values, ",")}

      {:tags, values} ->
        {:tags, Enum.join(values, ",")}

      {:categories, values} ->
        {:categories, values |> :json.encode() |> IO.iodata_to_binary()}

      {:properties, value} ->
        {:properties, value |> :json.encode() |> IO.iodata_to_binary()}

      {key, value} ->
        {key, value}
    end)
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
