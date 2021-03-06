defmodule XrayWeb.LayoutView do
  use XrayWeb, :view

  def active_class(conn, path) do
    current_path = Path.join(["/", conn.path_info])

    if path == current_path do
      "link-button active"
    else
      "link-button"
    end
  end
end
