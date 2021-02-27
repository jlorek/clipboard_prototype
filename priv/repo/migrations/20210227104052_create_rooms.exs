defmodule Clipboard.Repo.Migrations.CreateRooms do
  use Ecto.Migration

  # mix phx.gen.context Organizer Room rooms title:string slug:string
  def change do
    create table(:rooms) do
      add :title, :string
      add :slug, :string

      timestamps()
    end

    create unique_index(:rooms, :slug)
  end
end
