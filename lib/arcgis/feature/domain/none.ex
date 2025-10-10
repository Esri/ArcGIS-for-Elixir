defmodule ArcGIS.Feature.Domain.None do
  defstruct []

  @typedoc """
  The default unconstrained domain for fields. Such a field may contain any
  (type-conformant) data.
  """
  @type t :: %__MODULE__{}
end
