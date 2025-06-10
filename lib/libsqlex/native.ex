defmodule LibSqlEx.Native do
  use Rustler,
    otp_app: :libsqlex,
    crate: :libsqlex

  # native bridge from rust check lib.rs
  def ping(_conn), do: :erlang.nif_error(:nif_not_loaded)
  def connect(_opts, _mode), do: :erlang.nif_error(:nif_not_loaded)
  def query_args(_conn, _mode, _query, _args, _sync), do: :erlang.nif_error(:nif_not_loaded)
  def begin_transaction(_conn), do: :erlang.nif_error(:nif_not_loaded)
  def execute_with_transaction(_trx_id, _query, _args), do: :erlang.nif_error(:nif_not_loaded)
  def handle_status_transaction(_trx_id), do: :erlang.nif_error(:nif_not_loaded)

  def commit_or_rollback_transaction(_trx, _conn, _mode, _sync, _param),
    do: :erlang.nif_error(:nif_not_loaded)

  def do_sync(_conn, _mode), do: :erlang.nif_error(:nif_not_loaded)
  def close(_id, _opt), do: :erlang.nif_error(:nif_not_loaded)

  # helper

  def sync(%LibSqlEx.State{conn_id: conn_id, mode: mode} = _state) do
    do_sync(conn_id, mode)
  end

  def close_conn(id, opt, state) do
    case close(id, opt) do
      :ok -> :ok
      {:error, message} -> {:error, message, state}
    end
  end

  def execute_non_trx(query, state, args) do
    query(state, query, args)
  end

  def query(
        %LibSqlEx.State{conn_id: conn_id, mode: mode, sync: syncx} = state,
        %LibSqlEx.Query{statement: statement} = query,
        args
      ) do
    case query_args(conn_id, mode, syncx, statement, args) do
      %{
        "columns" => columns,
        "rows" => rows,
        "num_rows" => num_rows
      } ->
        result = %LibSqlEx.Result{
          command: detect_command(statement),
          columns: columns,
          rows: rows,
          num_rows: num_rows
        }

        {:ok, query, result, state}

      {:error, message} ->
        {:error, query, message, state}
    end
  end

  def execute_with_trx(
        %LibSqlEx.State{conn_id: _conn_id, trx_id: trx_id} = state,
        %LibSqlEx.Query{statement: statement} = query,
        args
      ) do
    # nif NifResult<u64>
    case execute_with_transaction(trx_id, statement, args) do
      num_rows when is_integer(num_rows) ->
        result = %LibSqlEx.Result{
          command: detect_command(statement),
          num_rows: num_rows
        }

        {:ok, query, result, state}

      {:error, message} ->
        {:error, query, message, state}
    end
  end

  def begin(%LibSqlEx.State{conn_id: conn_id, mode: mode} = _state) do
    case begin_transaction(conn_id) do
      trx_id when is_binary(trx_id) ->
        {:ok, %LibSqlEx.State{conn_id: conn_id, trx_id: trx_id, mode: mode}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def commit(%LibSqlEx.State{conn_id: conn_id, trx_id: trx_id, mode: mode, sync: syncx} = _state) do
    commit_or_rollback_transaction(trx_id, conn_id, mode, syncx, "commit")
  end

  def rollback(
        %LibSqlEx.State{conn_id: conn_id, trx_id: trx_id, mode: mode, sync: syncx} = _state
      ) do
    commit_or_rollback_transaction(trx_id, conn_id, mode, syncx, "rollback")
  end

  def detect_command(query) do
    query
    |> String.downcase()
    |> String.trim()
    |> String.split()
    |> List.first()
    |> case do
      "select" -> :select
      "insert" -> :insert
      "update" -> :update
      "delete" -> :delete
      "begin" -> :begin
      "commit" -> :commit
      "create" -> :create
      "rollback" -> :rollback
      _ -> :unknown
    end
  end
end
