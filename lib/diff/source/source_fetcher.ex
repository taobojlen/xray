defmodule Diff.Source.SourceFetcher do
  use Oban.Worker, queue: :source_fetcher
  alias Diff.{Packages, Source, Storage}

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id}}) do
    version = Packages.get_version!(id)
    package = Packages.get_package!(version.package_id)

    files = store_files(package, version)
    files_list_key = save_files_list(files, package, version)

    Packages.update_version(version, %{source_uri: files_list_key})
  end

  defp store_files(package, version) do
    registry = get_registry()

    case registry.get_source(package.registry, package.name, version.version) do
      {:ok, tmp_path} ->
        files =
          Path.join([tmp_path, "**"])
          |> Path.wildcard(match_dot: true)
          |> Enum.filter(&File.regular?/1)
          |> Enum.reduce(%{}, fn path, acc ->
            filename = Path.relative_to(path, tmp_path)
            Map.put(acc, filename, path)
          end)
          |> Enum.map(fn {filename, path} ->
            content = File.read!(path)
            key = Source.get_storage_key(package.registry, package.name, version.version)
            Storage.put(key <> "/" <> filename, content)
            filename
          end)

        File.rm_rf!(tmp_path)
        files

      {:error, error} ->
        raise error
    end
  end

  defp save_files_list(files, package, version) do
    content = Enum.join(files, "\n")
    key = Source.get_files_list_key(package.registry, package.name, version.version)
    Storage.put(key, content)
    key
  end

  defp get_registry() do
    Application.get_env(:diff, :registry)
  end
end
