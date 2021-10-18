defmodule BlogWeb.PageControllerTest do
  use BlogWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = conn |> Plug.Conn.put_req_header("x-forwarded-proto", "https")
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Cory Buecker"
  end
end
