defmodule ArcGIS.Test.Fixtures.Network do
  @moduledoc false
  alias ArcGIS.Test.Helper

  def json(name) do
    "arcgis/#{name}.json" |> Helper.load_data() |> Jason.decode!()
  end
end
