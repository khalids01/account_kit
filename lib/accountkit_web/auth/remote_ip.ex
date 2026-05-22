defmodule AccountkitWeb.Auth.RemoteIp do
  @moduledoc """
  Reads the client IP from LiveView session or connect_info.
  """

  def from_socket(socket) do
    case Phoenix.LiveView.get_connect_info(socket, :peer_data) do
      %{address: address} -> format_ip(address)
      _ -> socket.assigns[:client_ip] || "unknown"
    end
  end

  def from_session(session) when is_map(session) do
    session["remote_ip"] || session[:remote_ip] || "unknown"
  end

  defp format_ip({a, b, c, d}), do: "#{a}.#{b}.#{c}.#{d}"

  defp format_ip(ip) when is_tuple(ip) do
    ip
    |> Tuple.to_list()
    |> Enum.map_join(":", &Integer.to_string/1)
  end

  defp format_ip(ip), do: to_string(ip)
end
