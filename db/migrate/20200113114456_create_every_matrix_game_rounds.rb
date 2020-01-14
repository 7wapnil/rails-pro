class CreateEveryMatrixGameRounds < ActiveRecord::Migration[5.2]
  def change # rubocop:disable Metrics/MethodLength
    create_table :every_matrix_game_rounds, id: false do |t|
      t.primary_key :external_id, :string
      t.string :status,
               null: false,
               default: EveryMatrix::GameRound::DEFAULT_STATUS
      t.timestamps
    end

    add_index :every_matrix_game_rounds, :status

    reversible do |dir|
      dir.up do
        change_column :every_matrix_transactions, :round_id, :string,
                      references: :every_matrix_game_rounds,
                      foreign_key: true
      end

      dir.down do
        change_column :every_matrix_transactions, :round_id, :string
      end
    end
  end
end
