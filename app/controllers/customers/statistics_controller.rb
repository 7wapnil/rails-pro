# frozen_string_literal: true

module Customers
  class StatisticsController < ApplicationController
    find :customer, by: :customer_id, decorate: true

    decorates_assigned :stats

    def show
      @stats = Customers::Statistics::Calculator.call(customer: @customer,
                                                      force: force)

      redirect_to customer_statistics_path(@customer, force: nil) if force
    end

    private

    def force
      params.permit(:force)[:force]
    end
  end
end
