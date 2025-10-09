defmodule ArcGIS.User do
  alias ArcGIS.Portal
  alias ArcGIS.Telemetry

  @type token_options :: {:referer, url :: String.t()} | {:portal_url, url :: String.t()}
  @spec generate_token(
          username :: String.t(),
          password :: String.t(),
          Portal.t(),
          options :: Portal.portal_options()
        ) ::
          String.t() | nil
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
