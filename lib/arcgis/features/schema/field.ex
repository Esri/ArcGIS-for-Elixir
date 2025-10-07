defmodule ArcGIS.Features.Schema.Field do
  alias ArcGIS.Features.Domain

  defstruct [
    :name,
    :label,
    :type,
    :type_label,
    domain: %Domain.None{},
    editable?: false,
    foreign_key?: false,
    primary_key?: false
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          label: String.t(),
          type: String.t(),
          type_label: String.t(),
          domain: Domain.t(),
          editable?: boolean,
          foreign_key?: boolean,
          primary_key?: boolean
        }
end
