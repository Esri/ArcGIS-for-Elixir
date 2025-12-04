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
