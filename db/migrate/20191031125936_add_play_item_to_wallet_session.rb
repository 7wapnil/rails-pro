class AddPlayItemToWalletSession < ActiveRecord::Migration[5.2]
  def change
    add_column :em_wallet_sessions, :play_item_id, :string, null: false

    add_index :em_wallet_sessions, :play_item_id

    add_foreign_key :em_wallet_sessions,
                    :every_matrix_play_items,
                    column: :play_item_id,
                    primary_key: 'external_id'
  end
end
