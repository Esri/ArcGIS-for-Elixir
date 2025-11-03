defmodule ArcGIS.User.Group do
  @moduledoc "A user group"

  alias ArcGIS.Portal

  alias ArcGIS.Timestamps
  # not included:
  #  * autoJoin
  #  * displaySettings
  #  * featuredItemsId
  #  * isFav
  #  * leavingDisallowed
  #  * phone
  #  * properties
  #  * protected
  #  * provider
  #  * providerGroupname
  #  * snippet
  #  * sortField
  #  * sortOrder
  #  * typeKeywords
  defstruct [
    :id,
    :access,
    :capabilities,
    :description,
    :invitation_only?,
    :membership_type,
    :notifications_enabled?,
    :owner,
    :tags,
    :read_only?,
    :thumbail,
    :timestamps,
    :title,
    :view_only?
  ]

  @type t :: %__MODULE__{
          id: Portal.id(),
          access: String.t(),
          capabilities: [String.t()],
          description: String.t(),
          invitation_only?: boolean,
          membership_type: boolean,
          notifications_enabled?: boolean,
          owner: String.t(),
          tags: [String.t()],
          read_only?: boolean,
          thumbail: String.t(),
          timestamps: Timestamps.t(),
          title: String.t(),
          view_only?: boolean
        }

  @spec new(map) :: [t()]
  @doc "Create a list of user groups from a response"
  def new(%{groups: groups}) when is_list(groups) do
    Enum.map(groups, &from_map/1)
  end

  def new(_), do: []

  defp from_map(%{} = group) do
    # TODO: confirm defaults make sense
    %__MODULE__{
      id: Map.get(group, "id", ""),
      access: Map.get(group, "access", ""),
      capabilities: Map.get(group, "capabilities", ""),
      description: Map.get(group, "description", ""),
      invitation_only?: Map.get(group, "isInvitationOnly", true),
      membership_type: group |> Map.get("userMembership", %{}) |> Map.get("memberType", ""),
      notifications_enabled?: Map.get(group, "notificationsEnabled", false),
      owner: Map.get(group, "owner", ""),
      tags: Map.get(group, "tags", []),
      read_only?: Map.get(group, "isReadOnly", false),
      thumbail: Map.get("thumnbnail", %{}),
      timestamps: timestamps_from_map(group),
      title: Map.get(group, "title", ""),
      view_only?: Map.get(group, "isViewOnly", false)
    }
  end

  defp timestamps_from_map(group) do
    %Timestamps{
      created: Map.get(group, "created", 0),
      modified: Map.get(group, "modified", 0),
      last_access: 0
    }
  end
end
