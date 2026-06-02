defmodule AccountkitWeb.Plugs.Cors do
  @moduledoc """
  Adds CORS headers for browser-based API clients.
  """

  import Plug.Conn

  @allowed_methods "GET, POST, PUT, PATCH, DELETE, OPTIONS"
  @default_allowed_headers "Content-Type, Authorization"
  @max_age "86400"

  def init(opts), do: opts

  def call(%Plug.Conn{method: "OPTIONS"} = conn, _opts) do
    conn
    |> put_cors_headers()
    |> send_resp(204, "")
    |> halt()
  end

  def call(conn, _opts) do
    register_before_send(conn, &put_cors_headers/1)
  end

  defp put_cors_headers(conn) do
    origin = conn |> get_req_header("origin") |> List.first()

    conn
    |> put_resp_header("access-control-allow-origin", origin || "*")
    |> put_resp_header("access-control-allow-methods", @allowed_methods)
    |> put_resp_header("access-control-allow-headers", requested_headers(conn))
    |> put_resp_header("access-control-max-age", @max_age)
    |> maybe_put_credentials(origin)
    |> maybe_put_vary(origin)
  end

  defp requested_headers(conn) do
    conn
    |> get_req_header("access-control-request-headers")
    |> List.first()
    |> case do
      value when is_binary(value) and value != "" -> value
      _value -> @default_allowed_headers
    end
  end

  defp maybe_put_credentials(conn, nil), do: conn

  defp maybe_put_credentials(conn, _origin),
    do: put_resp_header(conn, "access-control-allow-credentials", "true")

  defp maybe_put_vary(conn, nil), do: conn
  defp maybe_put_vary(conn, _origin), do: put_resp_header(conn, "vary", "Origin")
end
