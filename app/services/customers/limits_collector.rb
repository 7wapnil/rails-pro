# frozen_string_literal: true

module Customers
  class LimitsCollector < ApplicationService
    def initialize(customer:)
      @customer = customer
      @found_elements = []
      @built_elements = []
    end

    def call
      collect_limits!

      found_elements + built_elements
    end

    private

    attr_reader :customer, :found_elements, :built_elements

    def collect_limits!
      titles.map do |title|
        limit = limits_grouped_by_title_id[title.id]

        push_limit(limit, title)
      end
    end

    def titles
      @titles ||= Title.order(:name)
    end

    def limits_grouped_by_title_id
      @limits_grouped_by_title_id ||=
        BettingLimit.where(customer: customer)
                    .where.not(title: nil)
                    .to_a
                    .group_by(&:title_id)
                    .transform_values(&:first)
    end

    def push_limit(limit, title)
      return found_elements.push(limit: limit, title: title) if limit

      built_elements.push(
        limit: BettingLimit.new(customer: customer, title: title),
        title: title
      )
    end
  end
end
