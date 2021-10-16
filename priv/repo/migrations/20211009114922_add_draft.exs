defmodule Blog.Repo.Migrations.AddDraft do
  use Ecto.Migration

  def change do
    alter table(:pages) do
      add :draft, :boolean, null: false, default: false
    end
  end
end
