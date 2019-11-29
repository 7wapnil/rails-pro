# frozen_string_literal: true

module EveryMatrix
  class WalletSession < ApplicationRecord
    self.table_name = 'every_matrix_wallet_sessions'

    belongs_to :wallet
    belongs_to :play_item, foreign_key: :play_item_id
    delegate :customer, to: :wallet
  end
end
