# frozen_string_literal: true

module Customers
  class StatisticsController < ApplicationController
    find :customer, by: :customer_id, decorate: true

    decorates_assigned :stats

    def show
      @stats = Customers::Statistics::Calculator.call(customer: @customer)
    end
  end
end
