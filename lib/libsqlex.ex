defmodule LibSqlEx do
  @moduledoc """
  Documentation for `Libsqlex`.

  doesn't support handle_fetch, declare,  & deallocate
  """

  use DBConnection

  @impl true
  def connect(opts) do
    case LibSqlEx.Native.connect(opts, LibSqlEx.State.detect_mode(opts)) do
      conn_id when is_binary(conn_id) ->
        {:ok, %LibSqlEx.State{conn_id: conn_id, mode: LibSqlEx.State.detect_mode(opts)}}

      {:error, _} = err ->
        err

      other ->
        {:error, {:unexpected_response, other}}
    end
  end

  @impl true
  def ping(%LibSqlEx.State{conn_id: conn_id} = state) do
    case LibSqlEx.Native.ping(conn_id) do
      true -> {:ok, state}
      _ -> {:disconnect, :ping_failed, state}
    end
  end

  @impl true
  def disconnect(_opts, %LibSqlEx.State{conn_id: conn_id, trx_id: _trx_id} = state) do
    # return :ok on success
    LibSqlEx.Native.close_conn(conn_id, :conn_id, state)
  end

  @impl true
  def handle_execute(
        query,
        args,
        _opts,
        %LibSqlEx.State{conn_id: _conn_id, trx_id: trx_id, mode: _mode} = state
      ) do
    case trx_id do
      nil -> LibSqlEx.Native.execute_non_trx(query, state, args)
      _ -> LibSqlEx.Native.execute_with_trx(state, query, args)
    end
  end

  @impl true
  def handle_begin(_opts, state) do
    case LibSqlEx.Native.begin(state) do
      {:ok, new_state} -> {:ok, :begin, new_state}
      {:error, reason} -> {:error, reason, state}
    end
  end

  @impl true
  def handle_commit(_opts, state) do
    case LibSqlEx.Native.commit(
           %LibSqlEx.State{conn_id: conn_id, trx_id: _trx_id, mode: mode} = state
         ) do
      {:ok, _} ->
        {:ok, %LibSqlEx.Result{}, %LibSqlEx.State{conn_id: conn_id, mode: mode}}

      {:error, reason} ->
        {:disconnect, reason, state}
    end
  end

  @impl true
  def handle_rollback(_opts, %LibSqlEx.State{conn_id: conn_id, trx_id: _trx_id} = state) do
    case LibSqlEx.Native.rollback(state) do
      {:ok, _} ->
        {:ok, %LibSqlEx.Result{}, %LibSqlEx.State{conn_id: conn_id, trx_id: nil}}

      {:error, reason} ->
        {:disconnect, reason, state}
    end
  end

  @impl true
  def handle_close(_query, _opts, state) do
    {:ok, %LibSqlEx.Result{}, state}
  end

  @impl true
  def handle_status(_opts, %LibSqlEx.State{conn_id: _conn_id, trx_id: trx_id} = state) do
    case LibSqlEx.Native.handle_status_transaction(trx_id) do
      :ok -> {:transaction, state}
      {:error, message} -> {:disconnect, message, state}
    end
  end

  @impl true
  def handle_prepare(%LibSqlEx.Query{} = query, _opts, state) do
    {:ok, query, state}
  end

  @impl true
  def checkout(%LibSqlEx.State{conn_id: conn_id} = state) do
    case LibSqlEx.Native.ping(conn_id) do
      true -> {:ok, state}
      {:error, reason} -> {:disconnect, reason, state}
    end
  end

  @impl true
  def handle_fetch(_query, _cursor, _opts, state) do
    {:error, %ArgumentError{message: "Currently does't support fetch "}, state}
  end

  @impl true
  def handle_deallocate(_query, _cursor, _opts, state) do
    {:error, %ArgumentError{message: "Currently does't support deallocate "}, state}
  end

  @impl true
  def handle_declare(_query, _params, _opts, state) do
    {:error, %ArgumentError{message: "Currently does't support declare "}, state}
  end
end
