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

 defmodule ArcGIS.Portal.Macros do
  @moduledoc false

  defmacro geometry_module_for(esri_type, geometry_module_string) do
    # to_string(geometry_atom)
    geometry_string = geometry_module_string
    geometry_atom = String.to_atom("Elixir." <> geometry_string)
    geometry_z = String.to_atom("Elixir." <> geometry_string <> "Z")
    geometry_m = String.to_atom("Elixir." <> geometry_string <> "M")
    geometry_zm = String.to_atom("Elixir." <> geometry_string <> "ZM")

    quote do
      @spec geometry_module_for(esri_type :: String.t(), z? :: boolean, m? :: boolean) ::
              geometry_struct :: atom
      def geometry_module_for(unquote(esri_type), false, false), do: unquote(geometry_atom)
      def geometry_module_for(unquote(esri_type), true, false), do: unquote(geometry_z)
      def geometry_module_for(unquote(esri_type), false, true), do: unquote(geometry_m)
      def geometry_module_for(unquote(esri_type), true, true), do: unquote(geometry_zm)
    end
  end
end
