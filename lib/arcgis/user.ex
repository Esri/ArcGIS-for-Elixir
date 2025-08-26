defmodule ArcGIS.User do
  alias ArcGIS.Portal

  @type token_options :: {:referer, url :: String.t()} | {:portal_url, url :: String.t()}
  @spec generateToken(username :: String.t(), password :: String.t(), options :: String.t() | nil) ::
          String.t() | nil
  def generateToken(username, password, options \\ []) do
    params =
      %{
        username: username,
        password: password,
        client: ArcGIS.client_id(),
        referer: referer(options)
      }

    query_options =
      []
      |> with_portal(options)

    post_options = [
      form: params,
      connect_options: [transport_opts: [verify: :verify_none]]
    ]

    with request_params <- Portal.request_url("/generateToken", query_options),
         {:ok, %{body: %{"token" => token}}} <- Req.post(request_params, post_options) do
      {:ok, token}
    else
      error -> Portal.handle_error(error)
    end
  end

  defp with_portal(query_options, options) do
    case Keyword.get(options, :portal_url) do
      nil -> query_options
      url -> Keyword.put(query_options, :portal, %ArcGIS.Portal{portal_url: url})
    end
  end

  defp referer(options) do
    Keyword.get_lazy(options, :referer, &ArcGIS.client_id/0)
  end
end
