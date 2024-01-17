# EctoContract

## Description

The small library that will help you organize cast and validation logic
for params in your phoenix controllers (REST API) using Ecto

## Installation

Add `ecto_contract` to your deps in `mix.exs` file:

```elixir
def deps do
  [
    {:ecto_contract, github: "senconscious/ecto_contract", tag: "v0.0.2"}
  ]
end
```

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
