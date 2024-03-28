defmodule EctoContractTest do
  use ExUnit.Case, async: true

  defmodule DealIndexParam do
    use Ecto.Schema

    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :page, :integer, default: 1
      field :page_size, :integer, default: 10
      field :user_id, :integer
      field :office_id, :integer

      embeds_one :funnel, Funnel, primary_key: false do
        field :name, :string
      end
    end

    def changeset(entity, attrs, _context) do
      fields = entity.__struct__.__schema__(:fields) -- [:funnel]

      entity
      |> cast(attrs, fields)
      |> validate_required([:user_id])
      |> cast_embed(:funnel, with: &funnel_contract/2)
    end

    defp funnel_contract(entity, attrs) do
      cast(entity, attrs, [:name])
    end
  end

  test "happy path" do
    assert {:ok, data} = EctoContract.validate(DealIndexParam, %{user_id: 1})

    assert is_struct(data)

    assert data.page == 1
    assert data.page_size == 10
    assert data.user_id == 1
    refute data.office_id
  end

  test "missing user_id" do
    assert {:error, changeset} = EctoContract.validate(DealIndexParam, %{})

    assert errors_on(changeset).user_id == ["can't be blank"]
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts
        |> Keyword.get(String.to_existing_atom(key), key)
        |> to_string()
      end)
    end)
  end
end
