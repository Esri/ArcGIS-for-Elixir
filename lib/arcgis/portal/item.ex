defmodule ArcGIS.Portal.Item do
  alias ArcGIS.Portal

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
      |> Keyword.put(:transform, &to_struct/1)

    Portal.get(portal, "/search", all_options)
  end

  @spec get(Portal.t(), id :: String.t(), options :: [Portal.portal_option()]) ::
          {:ok, map} | {:error, reason :: String.t()}
  def get(%Portal{} = portal, id, options \\ []) when is_binary(id) do
    Portal.get(portal, "/content/items/#{id}", options)
  end

  def to_struct(arcgis_map) do
    arcgis_map
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
