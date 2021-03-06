defmodule XrayWeb.ViewSourceLive do
  use XrayWeb, :live_view
  # alias Xray.Packages.{Package, Version}
  alias Xray.{Source, Storage}

  @impl true
  def mount(%{"package" => package, "version" => version} = params, _session, socket) do
    registry = "npm"
    package = URI.decode(package) |> String.replace(" ", "/")
    version = URI.decode(version)
    Source.subscribe(registry, package, version)
    Task.start_link(fn -> Source.get_source(registry, package, version) end)

    filename =
      if params["filename"] do
        URI.decode(params["filename"])
      else
        nil
      end

    {:ok,
     assign(
       socket,
       registry: registry,
       package: package,
       version: version,
       loading: true,
       error: nil,
       files: %{},
       files_list: [],
       current_file: filename,
       code: nil,
       file_type: nil
     )}
  end

  @impl true
  def handle_event(
        "select_file",
        %{"f" => filename},
        %{assigns: %{package: package, version: version, files: files}} = socket
      ) do
    content =
      files
      |> Map.get(filename)
      |> maybe_get_file_content()

    socket =
      assign(
        socket,
        code: content,
        current_file: filename,
        file_type: get_file_extension(filename)
      )

    {:noreply,
     push_patch(socket,
       to: Routes.view_source_path(socket, :index, package, version, filename),
       replace: true
     )}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info(
        {Source, :not_found, _content},
        %{assigns: %{registry: registry, package: package, version: version}} = socket
      ) do
    Source.unsubscribe(registry, package, version)
    {:noreply, assign(socket, loading: false, error: "Not found")}
  end

  @impl true
  def handle_info(
        {Source, :error, error},
        %{assigns: %{registry: registry, package: package, version: version}} = socket
      ) do
    Source.unsubscribe(registry, package, version)
    {:noreply, assign(socket, loading: false, error: error)}
  end

  @impl true
  def handle_info(
        {Source, :found_source, files_list_key},
        %{assigns: %{current_file: filename, package: package, version: version}} = socket
      ) do
    files =
      Storage.get(files_list_key)
      |> Jason.decode!()

    files_list =
      files
      |> Enum.map(fn {filename, _key} -> filename end)
      |> Enum.sort()

    filename =
      if filename do
        filename
      else
        hd(files_list)
      end

    content =
      files
      |> Map.get(filename)
      |> maybe_get_file_content()

    file_type = get_file_extension(filename)

    socket =
      assign(socket,
        files: files,
        files_list: files_list,
        current_file: filename,
        code: content,
        file_type: file_type,
        loading: false
      )

    {:noreply,
     push_patch(socket,
       to: Routes.view_source_path(socket, :index, package, version, filename),
       replace: true
     )}
  end

  defp get_file_extension(filename) do
    String.split(filename, ".")
    |> List.last()
  end

  defp maybe_get_file_content(key) do
    content = Storage.get(key)

    cond do
      byte_size(content) > 1_000_000 ->
        "Cannot display files larger than 1MB"

      not String.valid?(content) ->
        "Cannot display binary file"

      true ->
        content
    end
  end
end
