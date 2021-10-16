defmodule BlogWeb.PageView do
  use BlogWeb, :view

  @spec compiled_body(String.t()) :: String.t()
  def compiled_body(markdown) do
    {:ok, ast, []} = EarmarkParser.as_ast(markdown, code_class_prefix: "language-")

    Earmark.Transform.transform(ast |> rewrite_nodes(), %{pretty: false, indent: 0})
  end

  defp rewrite_nodes(ast) do
    Traverse.mapall(
      ast,
      fn
        {"a", x, y, z} ->
          {"tracked-anchor", [], [{"a", x, y, z}], %{}}

        other ->
          other
      end,
      [{:post, true}]
    )
  end
end
