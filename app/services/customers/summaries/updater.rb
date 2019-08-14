# frozen_string_literal: true

module Customers
  module Summaries
    class Updater < ApplicationService
      INCREMENT_ATTRIBUTES = %i[bonus_payout_amount
                                real_money_payout_amount
                                bonus_deposit_amount
                                real_money_deposit_amount
                                withdraw_amount
                                signups_count].freeze
      NEGATIVE_INCREMENT_ATTRIBUTES = %i[bonus_wager_amount
                                         real_money_wager_amount].freeze
      APPEND_ATTRIBUTES = [:betting_customer_ids].freeze

      def initialize(day, attributes)
        @attributes = attributes
        @day = day
      end

      def call
        attributes.each_pair do |key, value|
          update_summary_attribute(key, value)
        end
      end

      private

      attr_reader :attributes, :day

      def summary
        @summary ||= Customers::Summary.find_or_create_by(day: day)
      rescue ActiveRecord::RecordNotUnique
        @summary = Customers::Summary.all.reload.find_by!(day: day)
      end

      def update_summary_attribute(key, value)
        case key.to_sym
        when *INCREMENT_ATTRIBUTES
          summary.increment!(key, value)
        when *NEGATIVE_INCREMENT_ATTRIBUTES
          summary.increment!(key, -value)
        when *APPEND_ATTRIBUTES
          Customers::Summary
            .where(id: summary.id)
            .update_all(["#{key} = array_append(#{key}, ?)", value])
        else
          raise NotImplementedError,
                "#{key} update not implemented for Customers::Summary"
        end
      end
    end
  end
end
