defmodule EctoContract do
  @moduledoc """
  Behaviour to validate your controller request params using ecto schema and changeset

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
  """

  @callback changeset(entity :: struct(), attrs :: map(), options :: keyword()) ::
              Ecto.Changeset.t()

  defmacro __using__(_opts) do
    quote do
      @behaviour EctoContract

      import Ecto.Changeset, only: [apply_action: 2]

      @doc """
      Casts params and validates them using predefined Ecto.Changeset.

      On success returns ok tuple with casted params as map as second element:

      ```elixir
      {:ok, validated_okay_params} = AcmeWeb.Post.IndexContract.cast_and_validate(okay_params)
      ```

      On error returns error tuple with Ecto.Changeset as second element:

      ```elixir
      {:error, %Ecto.Changeset{errors: errors}} = AcmeWeb.Post.IndexContract.cast_and_validate(error_params)
      ```

      You can pass context via keyword as second argument:

      ```elixir
      # In your controller
      AcmeWeb.Post.IndexContract.cast_and_validate(params, user: current_user)

      # In your contract module
      ...
      def changeset(entity, params, user: current_user) do
      ...
      ```

      For full usage example please see docs for `EctoContract`
      """
      @spec cast_and_validate(params :: map(), options :: keyword()) ::
              {:ok, map()} | {:error, Ecto.Changeset.t()}
      def cast_and_validate(params, options \\ []) do
        case apply_changeset(__MODULE__, params, options) do
          {:ok, applied_params} -> {:ok, deep_map_from_struct(applied_params)}
          {:error, error} -> {:error, error}
        end
      end

      defp apply_changeset(schema, params, options) do
        schema
        |> struct()
        |> schema.changeset(params, options)
        |> apply_action(:insert)
      end

      defp deep_map_from_struct(struct) when is_struct(struct) do
        for {key, value} <- Map.from_struct(struct),
            into: %{},
            do: {key, deep_map_from_struct(value)}
      end

      defp deep_map_from_struct(not_struct), do: not_struct
    end
  end
end
