defmodule ArcGIS.User do
  @moduledoc "User accounts hosted by an ArcGIS organisation."

  alias ArcGIS.Portal
  alias ArcGIS.Telemetry
  alias ArcGIS.Timestamps
  alias ArcGIS.User.{Culture, Group, Role}

  # not included:
  #   * favGroupId
  #   * categories
  #   * storageQuota
  #   * mfaEnabled
  #   * mfaEnformcementExempt
  #   * udn
  #   * preferredView
  #   * idpUsername
  #   * emailStatus
  defstruct [
    :id,
    :access,
    :culture,
    :description,
    :email,
    :groups,
    :license,
    :name,
    :org_id,
    :privileges,
    :provider,
    :region,
    :role,
    :storage_usage,
    :tags,
    :thumbnail,
    :timestamps,
    :user_type
  ]

  @type names :: %{
          user: String.t(),
          full: String.t(),
          first: String.t(),
          last: String.t()
        }

  @type t :: %__MODULE__{
          id: Portal.id(),
          access: String.t(),
          culture: Culture.t(),
          description: String.t(),
          email: String.t(),
          groups: [Group.t()],
          license: String.t() | nil,
          name: names(),
          org_id: Portal.id(),
          privileges: [String.t()],
          provider: String.t(),
          region: String.t(),
          role: Role.t(),
          storage_usage: non_neg_integer(),
          tags: [String.t()],
          thumbnail: String.t(),
          timestamps: Timestamps.t(),
          user_type: String.t()
        }

  @spec from_token(Portal.t(), auth_token :: String.t()) :: {:ok, map} | {:error, term}
  @doc """
  Given a portal and an auth token, returns the information related to the user account
  associated with the token, if any.
  """
  def from_token(%Portal{} = portal, auth_token) when is_binary(auth_token) do
    resource = "/community/self"

    post_options = [
      form: %{},
      connect_options: [timeout: ArcGIS.default_query_timeout()],
      receive_timeout: ArcGIS.default_query_timeout()
    ]

    with request <- Portal.build_request(resource, portal: portal, auth_token: auth_token),
         {:ok, %{body: user}} <- Req.post(request, post_options) do
      {:ok, from_map(user)}
    else
      error ->
        Telemetry.handle_error(error)
    end
  end

  @spec can?(t(), privilege :: String.t()) :: boolean()
  @doc "Checks if a user has a given privilege"
  def can?(%__MODULE__{privileges: privileges}, privilege) do
    Enum.member?(privileges, privilege)
  end

  @spec generate_token(
          username :: String.t(),
          password :: String.t(),
          Portal.t(),
          options :: [Portal.request_option()]
        ) ::
          String.t() | nil
  @doc """
  Generates a token for a given user on a portal. If to be used with a web frontend,
  pass in `referer` value via the `options` parameter.
  """
  def generate_token(username, password, %Portal{} = portal, options \\ []) do
    params =
      %{
        username: username,
        password: password,
        client: ArcGIS.client_id(),
        referer: referer(options)
      }

    query_options = Keyword.put(options, :portal, portal)

    post_options =
      [
        form: params,
        connect_options: [transport_opts: [verify: :verify_none]]
      ]

    with request <- Portal.build_request("/generateToken", query_options),
         {:ok, %{body: %{"token" => token}}} <- Req.post(request, post_options) do
      {:ok, token}
    else
      error ->
        Telemetry.handle_error(error)
    end
  end

  defp referer(options) do
    Keyword.get_lazy(options, :referer, &ArcGIS.client_id/0)
  end

  defp from_map(raw) do
    Map.get(raw, "", "")

    %__MODULE__{
      id: Map.get(raw, "id"),
      access: Map.get(raw, "access", ""),
      culture: Culture.new(raw),
      description: Map.get(raw, "description", ""),
      email: Map.get(raw, "email", ""),
      groups: Group.new(raw),
      name: names_from_map(raw),
      org_id: Map.get(raw, "orgId", ""),
      privileges: Map.get(raw, "privileges", []),
      provider: Map.get(raw, "provider", ""),
      # Should region be in culture?
      region: Map.get(raw, "region", ""),
      role: Role.new(raw),
      storage_usage: Map.get(raw, "storageUsage", ""),
      tags: Map.get(raw, "tags", []),
      thumbnail: Map.get(raw, "thumbnail", []),
      timestamps: timestamps_from_map(raw),
      license: Map.get(raw, "userLincenseTypeId"),
      user_type: Map.get(raw, "userType", "")
    }
  end

  defp timestamps_from_map(raw) do
    %Timestamps{
      created: Map.get(raw, "created"),
      last_access: Map.get(raw, "lastLogin"),
      modified: Map.get(raw, "modified")
    }
  end

  defp names_from_map(raw) do
    %{
      user: Map.get(raw, "username", ""),
      full: Map.get(raw, "fullName", ""),
      first: Map.get(raw, "firstName", ""),
      last: Map.get(raw, "lastName", "")
    }
  end
end
