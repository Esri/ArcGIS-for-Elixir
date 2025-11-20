defmodule ArcGISTest do
  use ExUnit.Case
  doctest ArcGIS

  test "check_for_error/2 returns the original term on error" do
    [
      {:error, "Error"},
      {:ok, %Req.Response{body: %{}}},
      {:ok, %Req.Response{body: %{"error" => %{}}}},
      {:ok, %Req.Response{status: 100, body: %{"something" => "yes"}}},
      {:ok, %Req.Response{status: 300, body: %{"something" => "yes"}}}
    ]
    |> Enum.each(fn error ->
      assert(ArcGIS.check_for_error(error) === error)
    end)
  end

  test "check_for_error/2 returns the :noerror on non-error" do
    [
      {:ok, :ok},
      {:ok, %Req.Response{status: 200, body: %{"something" => "yes"}}}
    ]
    |> Enum.each(fn error ->
      assert(ArcGIS.check_for_error(error) === :noerror)
    end)
  end
end
