defmodule ArcGIS.User do
  @moduledoc "User accounts on ArcGIS"
  alias ArcGIS.Portal
  alias ArcGIS.Telemetry

  @spec generate_token(
          username :: String.t(),
          password :: String.t(),
          Portal.t(),
          options :: Portal.portal_options()
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
