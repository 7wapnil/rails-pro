class CreateEveryMatrixFreeSpinBonuses < ActiveRecord::Migration[5.2]
  def change # rubocop:disable Metrics/MethodLength
    create_table :every_matrix_free_spin_bonuses do |t|
      t.references :every_matrix_vendor
      t.integer    :bonus_source, null: false, default: 2
      t.integer    :number_of_free_rounds
      t.date       :free_rounds_end_date
      t.json       :additional_parameters

      t.timestamps
    end

    create_table :every_matrix_free_spin_bonus_wallets do |t|
      t.references :every_matrix_free_spin_bonus,
                   foreign_key: true,
                   index: { name: 'index_customer_free_spin_bonus_id' }
      t.references :wallet
      t.string     :status
      t.string     :last_request_name
      t.json       :last_request_result
      t.json       :last_request_body

      t.timestamps
    end

    create_table :every_matrix_free_spin_bonus_play_items do |t|
      t.references :every_matrix_free_spin_bonus,
                   foreign_key: true,
                   index: { name: 'index_play_item_free_spin_bonus_id' }
      t.references :every_matrix_play_item,
                   type: :string,
                   foreign_key: { to_table: :every_matrix_play_items,
                                  primary_key: :external_id },
                   index: { name: 'index_free_spin_bonus_play_item_id' }

      t.timestamps
    end
  end
end
