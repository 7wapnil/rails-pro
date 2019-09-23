class CreateEmWagers < ActiveRecord::Migration[5.2]
  def change # rubocop:disable Metrics/MethodLength
    enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')

    create_table :em_wagers,
                 id: :uuid,
                 default: 'gen_random_uuid()' do |t|
      t.references :em_wallet_session, foreign_key: true, type: :uuid
      t.references :customer, foreign_key: true
      t.decimal :amount, precision: 14, scale: 2
      t.string :game_type
      t.string :gp_game_id
      t.integer :gp_id
      t.string :em_game_id
      t.string :product
      t.string :round_id
      t.string :device
      t.bigint :transaction_id, null: false, uniqie: true
      t.string :round_status
    end
  end
end
