# frozen_string_literal: true

module Customers
  class StatisticsController < ApplicationController
    find :customer, by: :customer_id

    decorates_assigned :stats

    def show
      @stats = Customers::Statistics::Calculator.call(customer: @customer,
                                                      force: force)
    end

    private

    def force
      params.permit(:force)[:force]
    end
  end
end
