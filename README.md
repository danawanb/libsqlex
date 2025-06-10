# Libsqlex

LibSqlEx is an Elixir database adapter built on top of Rust NIFs to provide a native driver connection to libSQL/Turso.
Support Local, Remote Replica, and Remote Only via options.

⚠️ Currently, it does not support cursor operations such as fetch, declare, and deallocate. 

## Installation

the package can be installed
by adding `libsqlex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:libsqlex, "~> 0.1.0"}
  ]
end
```

## Usage
```elixir
defmodule Example do
  alias LibSqlEx.State

  def run_query do
    # Connect to the database via remote replica
    opts = [
      uri: System.get_env("LIBSQL_URI"),
      auth_token: System.get_env("LIBSQL_TOKEN"),
      database: "bar.db",
      # false if disable auto sync local and remote
      sync: true,
    ]
    case LibSqlEx.connect(opts) do
      {:ok, state} ->
        # Example: Execute a simple query without transaction
        {:ok, result, _state} = LibSqlEx.handle_execute("SELECT 1", [], [], state)
        IO.inspect(result, label: "Query Result")

        query= "CREATE TABLE users (
                id INTEGER PRIMARY KEY,
                name TEXT);"

        {:ok, create, _state} = LibSqlEx.handle_execute(query, [], [], state)
        IO.inspect(create, label: "Create Table Result")

        {:ok, insert, _state} = LibSqlEx.handle_execute("INSERT INTO users (name) VALUES (?)", ["Alice"], [], state)
        IO.inspect(insert, label: "Insert Table Result")

        {:ok, select, _state} = LibSqlEx.handle_execute("SELECT * FROM USERS;", [], [], state)
        IO.inspect(select, label: "Select Result")

      {:error, reason} ->
        IO.puts("Failed to connect: #{inspect(reason)}")
    end
  end
end
```

## Local Opts
```elixir
    opts = [
      database: "bar.db",
    ]

```

## Remote Only Opts
```elixir

    opts = [
      uri: System.get_env("LIBSQL_URI"),
      auth_token: System.get_env("LIBSQL_TOKEN"),
    ]
```

### Manual Sync
```elixir
defmodule Example do
  alias LibSqlEx.State

  def run_query do
    # Connect to the database via remote replica
    opts = [
      uri: System.get_env("LIBSQL_URI"),
      auth_token: System.get_env("LIBSQL_TOKEN"),
      database: "bar.db",
      sync: false,
    ]
    case LibSqlEx.connect(opts) do
      {:ok, state} ->
        {:ok, insert, _state} = LibSqlEx.handle_execute("INSERT INTO users (name) VALUES (?)", ["Alice"], [], state)
        IO.inspect(insert, label: "Insert Table Result")

        {:ok, _} =  LibSqlEx.Native.sync(state);

      {:error, reason} ->
        IO.puts("Failed to connect: #{inspect(reason)}")
    end
  end
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/libsqlex>.
