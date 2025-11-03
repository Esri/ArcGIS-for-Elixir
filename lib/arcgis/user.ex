defmodule ArcGIS.User do
  @moduledoc "User accounts hosted by an ArcGIS organisation."

  alias ArcGIS.Portal
  alias ArcGIS.Telemetry

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
      {:ok, user}
    else
      error ->
        Telemetry.handle_error(error)
    end
  end

  @spec username(map) :: String.t()
  @doc "Returns the user name from a user map."
  def username(%{"username" => username}), do: username

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
end
