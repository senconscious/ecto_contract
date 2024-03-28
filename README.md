# EctoContract

## Description

The small library that will help you organize cast and validation logic
for params in your phoenix controllers (REST API) using Ecto

## Installation

Add `ecto_contract` to your deps in `mix.exs` file:

```elixir
def deps do
  [
    {:ecto_contract, github: "senconscious/ecto_contract", tag: "v0.0.3"}
  ]
end
```

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
    with {:ok, %DealIndexParam{} = casted_params} <- EctoContract.validate(DealIndexParam, params) do
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
