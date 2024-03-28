defmodule OldEctoContract do
  @moduledoc """
  Define contract for your params in controller using `Ecto.Schema` and `Ecto.Changeset`

  ## Usage

  1. Define your contract in your controller

  ```elixir
  defmodule AcmeWeb.PostController do
    # Imports macro `defcontract/2` for defining your contract
    # Also imports `field/3`, `embeds_one/3`, `embeds_many/3` from `Ecto.Schema`
    use EctoContract

    # Under the hood your contract schema will be defined under name
    # of current module concateneted with `IndexContract`
    defcontract :index do
      field :page, :integer
      field :page_size, :integer

      embeds_one :simple_filter, primary_key: false do
        field :name, :string
      end

      embeds_many :complex_filters, primary_key: false do
        field :id, :integer
      end
    end
  end
  ```

  2. Add simple cast logic function

  ```elixir
  # Still in your controller
  # Import `Ecto.Changeset` to make functions for handling changeset available
  import Ecto.Changeset

  defp index_contract(entity, attrs) do
    entity
    |> cast(attrs, [:page, :page_size])
    |> cast_embed(:simple_filter, with: &index_simple_filter_contract/2)
    |> cast_embed(:complex_filters, &index_complex_filter_contract/2)
  end

  defp index_simple_filter_contract(entity, attrs) do
    cast(entity, attrs, [:name])
  end

  defp index_complex_filter_contract(entity, attrs) do
    cast(entity, attrs, [:id])
  end
  ```

  3. Validate your contract in controller action

  ```elixir
  def index(conn, params) do
    with {:ok, casted_params} <- validate_contract(:index, params, [], &index_contract/2) do
      posts = Posts.list_posts(casted_params)
      render(conn, "index.json", posts: posts)
    end
  end
  ```
  """

  import Ecto.Changeset, only: [apply_action: 2]

  defmacro __using__(_opts) do
    quote do
      import EctoContract, only: [defcontract: 2]
      import Ecto.Schema, only: [field: 3, embeds_one: 3, embeds_many: 3]

      @spec validate_contract(name :: atom(), params :: map(), context :: keyword(), function()) ::
              {:ok, map()} | {:error, Ecto.Changeset.t()}
      def validate_contract(name, params, context, function)
          when is_atom(name) and is_function(function) do
        __MODULE__
        |> EctoContract.contract_module(name)
        |> EctoContract.validate_contract(params, context, function)
      end
    end
  end

  defmacro defcontract(name, block) do
    quote do
      defmodule EctoContract.contract_module(__MODULE__, unquote(name)) do
        use Ecto.Schema

        @primary_key false
        embedded_schema(unquote(block))
      end
    end
  end

  def contract_module(module, local_name) when is_atom(module) and is_atom(local_name) do
    trimmed_local_name =
      local_name
      |> Atom.to_string()
      |> String.capitalize()

    Module.concat(module, trimmed_local_name <> "Contract")
  end

  def validate_contract(contract_module, attrs, context, function) do
    case apply_contract(contract_module, attrs, context, function) do
      {:ok, applied_params} -> {:ok, deep_map_from_struct(applied_params)}
      {:error, error} -> {:error, error}
    end
  end

  defp apply_contract(module, attrs, context, function) do
    module
    |> struct()
    |> function.(attrs, context)
    |> apply_action(:insert)
  end

  defp deep_map_from_struct(struct) when is_struct(struct) do
    for {key, value} <- Map.from_struct(struct),
        into: %{},
        do: {key, deep_map_from_struct(value)}
  end

  defp deep_map_from_struct(not_struct), do: not_struct
end
