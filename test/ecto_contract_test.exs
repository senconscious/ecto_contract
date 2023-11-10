defmodule EctoContractTest do
  use ExUnit.Case, async: true

  alias EctoContract.AcmeWeb.Post.IndexContract

  test "puts defaults on empty params" do
    {:ok, params} = IndexContract.cast_and_validate(%{})

    assert params.page == 1
    assert params.page_size == 10
    assert params.sort_by == "author_name"
    assert params.sort_direction == "desc"
    assert is_nil(params.user_id)
  end

  test "puts user_id" do
    user_id = 10

    {:ok, params} = IndexContract.cast_and_validate(%{}, user_id: user_id)

    assert params.user_id == user_id
  end

  test "fails on invalid parameter" do
    {:error, %Ecto.Changeset{} = changeset} = IndexContract.cast_and_validate(%{page: -1})

    assert traverse_errors(changeset).page == ["must be greater than or equal to 1"]
  end

  defp traverse_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
