# frozen_string_literal: true

module Em
  class Wager < ApplicationRecord
    self.table_name = 'em_wagers'

    belongs_to :em_wallet_session
    belongs_to :customer
  end
end
