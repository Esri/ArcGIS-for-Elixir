defmodule ArcGIS.Test.Fixtures.Network do
  alias ArcGIS.Test.Helper

  def json(name) do
    "arcgis/#{name}.json" |> Helper.load_data() |> Jason.decode!()
  end
end
