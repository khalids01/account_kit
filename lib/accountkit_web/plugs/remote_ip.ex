defmodule AccountkitWeb.Plugs.RemoteIp do
  @moduledoc """
  Stores the client IP in the session for use in LiveViews.
  """
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    put_session(conn, :remote_ip, format_ip(conn.remote_ip))
  end

  defp format_ip({a, b, c, d}), do: "#{a}.#{b}.#{c}.#{d}"

  defp format_ip(ip) when is_tuple(ip) do
    ip
    |> Tuple.to_list()
    |> Enum.map_join(":", &Integer.to_string/1)
  end

  defp format_ip(ip), do: to_string(ip)
end
