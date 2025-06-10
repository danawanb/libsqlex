defmodule LibSqlEx.State do
  @enforce_keys [:conn_id]

  defstruct [
    :conn_id,
    :trx_id,
    :mode,
    :sync
  ]

  def detect_mode(opts) do
    has_uri = Keyword.has_key?(opts, :uri)
    has_token = Keyword.has_key?(opts, :auth_token)
    has_db = Keyword.has_key?(opts, :database)
    has_sync = Keyword.has_key?(opts, :sync)

    cond do
      has_uri and has_token and has_db and has_sync -> :remote_replica
      has_uri and has_token -> :remote
      has_db -> :local
      true -> :unknown
    end
  end

  def detect_sync(opts) do
    IO.inspect(opts)
    has_sync = Keyword.has_key?(opts, :sync)

    case has_sync do
      true -> get_sync(Keyword.get(opts, :sync))
      false -> :disable_sync
    end
  end

  defp get_sync(val) do
    case val do
      true -> :enable_sync
      false -> :disable_sync
    end
  end
end
