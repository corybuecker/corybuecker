defmodule Post do
  require Logger

  defstruct [:title, :slug, :published, :revised, :description, :body, :preview]

  def from_file(path) do
    {:ok, {frontmatter, body}} = parse_content_file(path)

    %Post{
      body: body,
      description: frontmatter["description"],
      published: maybe_date(DateTime.from_iso8601(frontmatter["published"] || "")),
      revised: maybe_date(DateTime.from_iso8601(frontmatter["revised"] || "")),
      slug: frontmatter["slug"],
      preview: frontmatter["preview"],
      title: frontmatter["title"]
    }
  end

  defp maybe_date({:ok, %DateTime{} = datetime, _}), do: datetime
  defp maybe_date(_), do: nil

  defp parse_content_file(path) when is_bitstring(path) do
    Logger.debug(path)

    with {:ok, file_contents} <- File.read(path),
         [frontmatter_string, body_string] <-
           file_contents |> String.split("---", parts: 2, trim: true),
         {:ok, frontmatter} <- frontmatter_string |> YamlElixir.read_from_string(),
         {:ok, body, _} <- body_string |> Earmark.as_html(postprocessor: postprocessor()) do
      {:ok, {frontmatter, body}}
    else
      err -> err
    end
  end

  defp postprocessor() do
    fn
      {"a", attributes, body, map} ->
        {"a", attributes ++ [{"class", "underline hover:no-underline"}], body, map}

      {"h2", attributes, body, map} ->
        {"h2", attributes ++ [{"class", "text-2xl"}], body, map}

      {"h3", attributes, body, map} ->
        {"h3", attributes ++ [{"class", "text-xl"}], body, map}

      {tag, attributes, body, map} ->
        {tag, attributes, body, map}

      string ->
        string
    end
  end
end
