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

1. Create `contracts` folder in your web domain
2. Define your params module using Ecto.Schema

```elixir
defmodule AcmeWeb.Post.IndexContract do
  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field :page, :integer, default: 1
    field :page_size, :integer, default: 10
    field :sort_by, :string, default: "author_name"
    field :sort_direction, :string, default: "desc"
  end
end
```

3. Use `EctoContract` on top of your module and define `changeset/3` callback.
   First argument is a struct of your embedded schema, second one - params to cast and validate,
   third one - options that you can pass from web domain to contract module

```elixir
defmodule AcmeWeb.Post.IndexContract do
  use Ecto.Schema
  # Add this one for utility functions
  use EctoContract

  # As usual for building changeset
  import Ecto.Changeset

  ...

  def changeset(entity, attrs, _options) do
    # Define changeset as usual
    entity
    |> cast(attrs, [:page, :page_size, :sort_by, :sort_direction])
    |> validate_required([:page, :page_size, :sort_by, :sort_direction])
    |> validate_number(:page, ...)
    ...
    |> validate_inclusion(:sort_direction, ["asc", "desc"])
  end
end
```

4. Call function to cast and validate params in your controller

```elixir
defmodule AcmeWeb.Posts do
  use AcmeWeb, :controller

  action_fallback AcmeWeb.FallbackController

  def index(conn, params) do
    with {:ok, params} <- AcmeWeb.Post.IndexContract.cast_and_validate(params) do
      ## Your're cool. Now your params casted and validated
      ...
    end
  end
end
```

You can also pass context from your web domain (for example current_user set in your
connection assings) into `changeset/3` function via third argument:

```elixir
def index(conn, params) do
  with {:ok, params} <- AcmeWeb.Post.IndexContract.cast_and_validate(params, user: conn.assigns.current_user) do
end
```

And in your `changeset/3`:

```elixir
def changeset(entity, attrs, user: user) do
  ...
end
```
