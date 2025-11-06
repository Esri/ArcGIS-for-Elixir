defmodule ArcGIS.Feature.Domain.None do
  @moduledoc """
  The default unconstrained domain for fields. Such a field may contain any
  (type-conformant) data.
  """

  defstruct []

  @type t :: %__MODULE__{}
end
