defmodule LibSqlEx.Result do
  defstruct command: nil,
            columns: nil,
            rows: nil,
            num_rows: 0

  # last_inserted_id: nil

  @type command_type :: :select | :insert | :update | :delete | :other

  @type t :: %__MODULE__{
          command: command_type,
          columns: [String.t()] | nil,
          rows: [[term]] | nil,
          num_rows: non_neg_integer()
          # last_inserted_id: term | nil
        }

  @spec new(Keyword.t()) :: t
  def new(options) do
    %__MODULE__{
      command: Keyword.get(options, :command, :other),
      columns: Keyword.get(options, :columns),
      rows: Keyword.get(options, :rows),
      num_rows: Keyword.get(options, :num_rows, 0)
      # last_inserted_id: Keyword.get(options, :last_inserted_id)
    }
  end
end
