defmodule ArcGIS.Feature.Query do
  alias ArcGIS.Utils

  @type aggregate_type :: :avg | :count | :max | :min | :sum
  @type aggregate :: %{type: aggregate_type, field: String.t(), name: String.t()}
  @type query_option ::
          {:where, String.t()}
          | {:fields, [String.t()]}
          | {:geometry?, boolean}
          | {:limit, non_neg_integer()}
          | {:offset, non_neg_integer()}
          | {:aggregates, [aggregate]}
  @type query_options :: [query_option]
  @spec args(options :: query_options) :: map
  def args(options \\ []) do
    %{
      where:
        options
        |> Keyword.get(:where)
        |> where(),
      outFields:
        options
        |> Keyword.get(:fields)
        |> out_fields(),
      returnGeometry: Keyword.get(options, :geometry?, false),
      resultRecordCount: Keyword.get(options, :limit) |> Utils.to_integer(10),
      resultOffset: Keyword.get(options, :offset) |> Utils.to_integer(0)
    }
    |> add_aggregates(Keyword.get(options, :aggregates))
  end

  defp add_aggregates(args, nil), do: args

  defp add_aggregates(args, aggregates) do
    args
    |> Map.delete(:outFields)
    |> Map.delete(:resultRecordCount)
    |> Map.delete(:resultOffset)
    |> Map.put(:outStatistics, to_aggregate_form(aggregates))
  end

  defp to_aggregate_form(aggregates) do
    Enum.map(
      aggregates,
      fn aggregate ->
        %{
          statisticType: aggregate.type,
          onStatisticField: aggregate.field,
          outStatisticFieldName: aggregate.name
        }
      end
    )
    |> :json.encode()
    |> to_string()
  end

  defp where(nil), do: "1=1"
  defp where(filter), do: filter

  defp out_fields(nil), do: "*"
  defp out_fields(fields), do: Enum.join(fields, ",")
end
