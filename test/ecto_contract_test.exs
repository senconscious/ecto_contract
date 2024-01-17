defmodule EctoContractTest do
  use ExUnit.Case, async: true
  use EctoContract

  # Import for defining contract validations
  import Ecto.Changeset

  defcontract :index do
    field :page, :integer, default: 1
    field :page_size, :integer, default: 10
    field :user_id, :integer

    embeds_one :funnel, Funnel, primary_key: false do
      field :name, :string
    end
  end

  defp index_contract(entity, attrs, _context) do
    fields = entity.__struct__.__schema__(:fields) -- [:funnel]

    entity
    |> cast(attrs, fields)
    |> validate_required([:user_id])
    |> cast_embed(:funnel, with: &funnel_contract/2)
  end

  defp funnel_contract(entity, attrs) do
    cast(entity, attrs, [:name])
  end

  test "generates embedded schema module" do
    assert %{page: 1, page_size: 10, user_id: nil, funnel: nil} = %__MODULE__.IndexContract{}
  end

  test "runs contract and returns map" do
    assert {:ok, %{funnel: casted_funnel} = casted_params} =
             validate_contract(
               :index,
               %{user_id: 1, funnel: %{name: "test"}},
               [],
               &index_contract/3
             )

    refute is_struct(casted_params)
    assert is_map(casted_params)

    refute is_struct(casted_funnel)
    assert is_map(casted_funnel)

    assert casted_funnel.name == "test"
  end

  test "returns error changeset" do
    assert {:error, changeset} = validate_contract(:index, %{}, [], &index_contract/3)

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
