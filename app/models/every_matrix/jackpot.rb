# frozen_string_literal: true

module EveryMatrix
  class Jackpot < ApplicationRecord
    self.table_name = :every_matrix_jackpots

    def self.total
      sum(:base_currency_amount)
    end
  end
end
