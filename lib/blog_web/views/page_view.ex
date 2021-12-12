defmodule BlogWeb.PageView do
  use BlogWeb, :view

  @spec compiled_body(String.t()) :: String.t()
  def compiled_body(markdown) do
    {:ok, ast, []} = EarmarkParser.as_ast(markdown, code_class_prefix: "lang- language-")

    Earmark.Transform.transform(ast |> rewrite_nodes())
  end

  defp rewrite_nodes(ast) do
    Traverse.mapall(
      ast,
      fn
        {"a", x, y, z} ->
          {"tracked-anchor", [], [{"a", x ++ [{"class", "underline hover:no-underline"}], y, z}],
           %{}}

        {"h2", attrs, y, z} ->
          {"h2", attrs ++ [{"class", "text-xl pt-2"}], y, z}

        other ->
          other
      end,
      [{:post, true}]
    )
  end
end
