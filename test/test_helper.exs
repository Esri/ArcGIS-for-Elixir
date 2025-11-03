defmodule ArcGIS.Test.Helper do
  defmacro __using__(_options \\ []) do
    quote do
      use ExUnit.Case
      alias ArcGIS.Test.Fixtures
      alias ArcGIS.Test.Helper
    end
  end

  def load_data(name) do
    File.read!("test/data/#{name}")
  end
end

Application.put_env(:arcgis, :req_defaults, plug: {Req.Test, ArcGIS})
ExUnit.start()
