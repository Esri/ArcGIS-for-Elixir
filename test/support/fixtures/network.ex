defmodule ArcGIS.Test.Fixtures.Network do
  @moduledoc false
  alias ArcGIS.Test.Fixtures

  def common_response(%{request_path: "/sharing/rest/content/items/test-feature-service"} = conn) do
    {:ok, Req.Test.json(conn, json("get_item"))}
  end

  def common_response(conn), do: {:no_common_match, conn}

  def json(name), do: Fixtures.test_json(name <> ".json", :arcgis)
end
