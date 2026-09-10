# Copyright 2026 Esri
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule ArcGIS.Test.Helper do
  defmacro __using__(options \\ []) do
    async = Keyword.get(options, :async, true)

    quote do
      use ExUnit.Case, async: unquote(async)
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
