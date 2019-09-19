# frozen_string_literal: true

class CreateEmWalletSessions < ActiveRecord::Migration[5.2]
  def change
    enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')

    create_table :em_wallet_sessions,
                 id: :uuid,
                 default: 'gen_random_uuid()' do |t|
      t.references :wallet
      t.timestamps
    end
  end
end
