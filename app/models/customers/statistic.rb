# frozen_string_literal: true

module Customers
  class Statistic < ApplicationRecord
    self.table_name = 'customer_statistics'

    belongs_to :customer, inverse_of: :statistics
  end
end
