defmodule LibSqlEx.State do
  @enforce_keys [:conn_id]

  defstruct [
    :conn_id,
    :trx_id,
    :mode
  ]

  def detect_mode(opts) do
    has_uri = Keyword.has_key?(opts, :uri)
    has_token = Keyword.has_key?(opts, :auth_token)
    has_db = Keyword.has_key?(opts, :database)

    cond do
      has_uri and has_token and has_db -> :remote_replica
      has_uri and has_token -> :remote
      has_db -> :local
      true -> :unknown
    end
  end
end
