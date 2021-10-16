defmodule Blog.Page do
  use Ecto.Schema
  import Ecto.Changeset

  schema "pages" do
    field :body, :string
    field :description, :string
    field :draft, :boolean
    field :published_at, :utc_datetime
    field :revised_at, :utc_datetime
    field :slug, :string
    field :title, :string

    timestamps()
  end

  @doc false
  def changeset(page, attrs) do
    page
    |> cast(attrs, [:slug, :body])
    |> validate_required([:slug, :body])
  end
end
