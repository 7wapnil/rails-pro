# frozen_string_literal: true

module Em
  class WalletSession < ApplicationRecord
    self.table_name = 'em_wallet_sessions'

    belongs_to :wallet
    delegate :customer, to: :wallet
  end
end
