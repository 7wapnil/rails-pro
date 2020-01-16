# frozen_string_literal: true

class AddPlayItemToTransaction < ActiveRecord::Migration[5.2]
  def up
    add_reference :every_matrix_transactions, :play_item,
                  foreign_key: {
                    to_table: :every_matrix_play_items,
                    primary_key: :external_id
                  },
                  type: :string

    execute <<~SQL
      update every_matrix_transactions
      set play_item_id = pi.external_id
      from every_matrix_play_items pi
      where pi.game_code = every_matrix_transactions.gp_game_id
    SQL
  end

  def down
    remove_reference :every_matrix_transactions, :play_item,
                     foreign_key: {
                       to_table: :every_matrix_play_items,
                       primary_key: :external_id
                     }
  end
end
