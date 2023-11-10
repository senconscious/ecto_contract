defmodule EctoContract.AcmeWeb.Post.IndexContract do
  use Ecto.Schema
  use EctoContract

  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :page, :integer, default: 1
    field :page_size, :integer, default: 10

    field :sort_by, :string, default: "author_name"
    field :sort_direction, :string, default: "desc"

    field :user_id, :integer
  end

  @impl EctoContract
  def changeset(entity, attrs, options) do
    fields = __schema__(:fields)
    required_fields = fields -- [:user_id]

    entity
    |> cast(attrs, fields)
    |> validate_required(required_fields)
    |> validate_number(:page, greater_than_or_equal_to: 1)
    |> validate_number(:page_size, greater_than_or_equal_to: 1, less_than_or_equal_to: 100)
    |> validate_inclusion(:sort_by, ["author_name", "inserted_at"])
    |> validate_inclusion(:sort_direction, ["asc", "desc"])
    |> put_user_id(options)
  end

  defp put_user_id(%{valid?: true} = changeset, user_id: user_id) do
    put_change(changeset, :user_id, user_id)
  end

  defp put_user_id(changeset, _options), do: changeset
end
