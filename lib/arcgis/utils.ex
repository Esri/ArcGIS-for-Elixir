# Copyright 2025 Esri
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

defmodule ArcGIS.Utils do
  @moduledoc false
  require Logger

  @doc """
  Prints the full set of metadata for a module, as known to Module:__info__.

  Returns: `:ok`.
  """
  @spec print_module_info(atom) :: :ok
  def print_module_info(modulename) do
    info_attrs = [
      :attributes,
      :compile,
      :exports,
      :functions,
      :macros,
      :md5,
      :module,
      :native_addresses
    ]

    attr_printer = fn x ->
      # credo:disable-for-lines:2
      IO.puts("== #{x}")
      IO.inspect(apply(modulename, :__info__, [x]))
    end

    Enum.each(info_attrs, attr_printer)
  end

  @local_telemetry_handler_name "arcgis_uteils_local_telemetry"

  @spec enable_local_telemetry(boolean) :: :ok
  @doc """
  Enables or disables a local telemetry handler which
  subscribes to interesting telemetry messages and forwards them
  to `Logger.info/1`. Useful for local debugging.
  """
  def enable_local_telemetry(false) do
    :telemetry.detach(@local_telemetry_handler_name)
  end

  def enable_local_telemetry(true) do
    messages = [
      [:finch, :request, :start],
      [:finch, :request, :stop],
      [:finch, :connect, :start],
      [:finch, :connect, :stop],
      [:finch, :send, :start],
      [:finch, :send, :stop],
      [:finch, :recv, :start],
      [:finch, :recv, :stop],
      [:arcgis, :request, :success],
      [:arcgis, :request, :error]
    ]

    :telemetry.attach_many(
      @local_telemetry_handler_name,
      messages,
      &__MODULE__.local_telemtry_handler/4,
      nil
    )

    :ok
  end

  @doc false
  def local_telemtry_handler(event_name, measurements, metadata, _config) do
    Logger.info("#{inspect(event_name)}: #{inspect(measurements)}")

    if Enum.member?([[:arcgis, :request, :success], [:arcgis, :request, :error]], event_name) do
      Logger.info("\t\t#{inspect(metadata)}")
    end

    :ok
  end

  @doc "Prints all pending messages in the process mailbox to console"
  @spec flush() :: :ok
  def flush do
    receive do
      msg ->
        # credo:disable-for-next-line
        IO.inspect(msg)
        flush()
    after
      10 -> :ok
    end
  end

  @doc "Times a function"
  @spec time(fun) :: float
  def time(function) do
    :timer.tc(function)
    |> elem(0)
    |> Kernel./(1_000_000)
  end

  @spec time(fun, list) :: float
  def time(function, args) do
    :timer.tc(function, args)
    |> elem(0)
    |> Kernel./(1_000_000)
  end

  @spec time(atom, atom, list) :: float
  def time(module, function, args) do
    :timer.tc(module, function, args)
    |> elem(0)
    |> Kernel./(1_000_000)
  end

  @spec ts_to_naive(timestamp :: integer) :: NaiveDateTime.t()
  def ts_to_naive(timestamp) do
    timestamp
    |> DateTime.from_unix!()
    |> DateTime.to_naive()
  end

  @doc """
  Ensures the input string is as most max_length characters long, replacing
  additional characters with an elipsis
  """
  @type elide_location :: :center | :right
  @spec elide(string :: String.t(), max_length :: non_neg_integer, elide_where :: elide_location) ::
          {:orig, String.t()} | {:elided, String.t()}
  def elide(string, max_length, elide_where \\ :center) do
    # TODO: elide on approx render size?
    length = String.length(string)

    if length <= max_length do
      {:orig, string}
    else
      {
        :elided,
        slice_for_elision(string, max_length, elide_where)
      }
    end
  end

  @spec elide!(string :: String.t(), max_length :: non_neg_integer, elide_where :: elide_location) ::
          String.t()
  def elide!(string, max_length, elide_where \\ :center) do
    string
    |> elide(max_length, elide_where)
    |> elem(1)
  end

  defp slice_for_elision(string, target_size, :center) do
    keep_length = Integer.floor_div(target_size, 2)

    String.slice(string, 0, keep_length) <>
      "…" <> String.slice(string, -keep_length, keep_length)
  end

  defp slice_for_elision(string, target_size, :right) do
    String.slice(string, 0, target_size) <> "…"
  end

  @doc "Returns a random string of printable characters"
  @spec random_string(num_bytes :: non_neg_integer, max_str_length :: non_neg_integer) ::
          String.t()
  def random_string(num_bytes, max_str_length \\ 0)

  def random_string(num_bytes, 0) do
    num_bytes
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end

  def random_string(num_bytes, max_str_length) do
    string = random_string(num_bytes)
    binary_part(string, 0, min(byte_size(string), max_str_length))
  end

  @doc "Transforms a string or number to an integer, safely, if possible"
  @spec to_integer(String.t() | number, default :: term) :: integer
  def to_integer(number, default \\ 0)
  def to_integer(number, _default) when is_integer(number), do: number

  def to_integer(string, default) when is_binary(string) do
    case Integer.parse(string) do
      {result, _} -> result
      _ -> default
    end
  end

  def to_integer(number, _default) when is_number(number), do: round(number)
  def to_integer(_, default), do: default

  @spec ensure_is_nil_or_list(term, default :: nil | (-> term) | term) :: list
  def ensure_is_nil_or_list(nil, _), do: nil
  def ensure_is_nil_or_list(term, default), do: ensure_is_list(term, default)

  @spec ensure_date_time(term) :: nil | DateTime.t()
  def ensure_date_time(%DateTime{} = datetime), do: datetime

  def ensure_date_time(seconds) when is_number(seconds) do
    case DateTime.from_unix(seconds) do
      {:ok, datetime} -> datetime
      _ -> nil
    end
  end

  def ensure_date_time(string) when is_binary(string) do
    case DateTime.from_iso8601(string) do
      {:ok, datetime, _} -> datetime
      _ -> nil
    end
  end

  def ensure_date_time(_), do: nil

  @spec ensure_is_list(term, default :: nil | (-> term) | term) :: list
  def ensure_is_list(term, default \\ nil)
  def ensure_is_list(list, _) when is_list(list), do: list
  def ensure_is_list(nil, nil), do: []
  def ensure_is_list(nil, default), do: default.()
  def ensure_is_list(:default, default), do: default.()
  def ensure_is_list(item, _), do: [item]

  @doc "Move a file, copy if we must"
  @spec move_file(src_path :: String.t(), dest_path :: String.t()) :: :ok | :error
  def move_file(src_path, dest_path) do
    # move if we can, copy if we have to
    case File.rename(src_path, dest_path) do
      {:error, :exdev} ->
        case File.copy(src_path, dest_path) do
          {:error, reason} ->
            Logger.error(
              "Failed to move by copy #{src_path} to #{dest_path} because #{inspect(reason)}"
            )

            :error

          _ ->
            :ok
        end

      {:error, reason} ->
        Logger.error("Failed to move #{src_path} to #{dest_path} because #{inspect(reason)}")
        :error

      _ ->
        :ok
    end
  end

  @doc "Returns a string, if it can"
  @type string_convertable :: atom | number | String.t() | binary
  @spec as_string([string_convertable] | string_convertable) :: String.t()
  def as_string(list) when is_list(list), do: Enum.join(list, " ")
  def as_string(other), do: to_string(other)

  @doc "Transmutes an error of some sort into a string"
  @spec error_to_string(error :: term) :: String.t()
  def error_to_string({:error, error}), do: error_to_string(error)
  def error_to_string(error) when is_binary(error), do: error
  def error_to_string(error), do: "#{inspect(error)}"
end
