defmodule EctoContract do
  @moduledoc """
  Provides helpers to validate your controller params with `Ecto.Schema`.

  ## Usage

  1. Define your params in `acme_web/params` folder

  ```elixir
  defmodule AcmeWeb.DealIndexParam do
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
  ```

  2. Easily validate params in your controller

  ```elixir
  defmodule AcmeWeb.DealController do
    use AcmeWeb, :controller

    alias AcmeWeb.DealIndexParam

    alias Acme.Deals

    def index(conn, params) do
      with {:ok, casted_params} <- EctoContract.validate(DealIndexParam, params) do
        deals = Deals.list_deals(casted_params)
        render(conn, "index.json", deals: deals)
      end
    end
  end
  ```

  ### Passing additional context

  ```elixir
  def index(conn, params) do
    with {:ok, casted_params} <- EctoContract.validate(DealIndexParam, params, user: conn.assigns.current_user) do
      deals = Deals.list_deals(casted_params)
      render(conn, "index.json", deals: deals)
    end
  end
  ```

  ### Deeply convert struct to map

  ```elixir
  def index(conn, params) do
    with {:ok, casted_params} <- EctoContract.validate(DealIndexParam, params, user: conn.assigns.current_user) do
      deals =
        casted_params
        |> EctoContract.to_map()
        |> Deals.list_deals()

      render(conn, "index.json", deals: deals)
    end
  end
  ```
  """

  import Ecto.Changeset, only: [apply_action: 2]

  @spec validate(module() | struct(), map(), any()) ::
          {:ok, struct()} | {:error, Ecto.Changeset.t()}
  def validate(module_or_struct, attrs, context \\ []) do
    validate_changeset(module_or_struct, attrs, context)
  end

  defp validate_changeset(struct, attrs, context) when is_struct(struct) do
    struct
    |> struct.__struct__.changeset(attrs, context)
    |> apply_action(:insert)
  end

  defp validate_changeset(module, attrs, context) when is_atom(module) do
    module
    |> struct()
    |> module.changeset(attrs, context)
    |> apply_action(:insert)
  end

  @spec to_map(struct() | map()) :: map()
  def to_map(struct) when is_struct(struct) do
    struct
    |> Map.from_struct()
    |> Map.new(&to_map/1)
  end

  def to_map(map) when is_map(map), do: Map.new(map, &to_map/1)

  def to_map({key, value}) when is_struct(value) do
    {key, to_map(value)}
  end

  def to_map({key, value}) when is_map(value) do
    {key, to_map(value)}
  end

  def to_map({key, value}), do: {key, value}
end
