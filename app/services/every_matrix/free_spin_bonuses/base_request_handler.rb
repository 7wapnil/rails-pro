# frozen_string_literal: true

module EveryMatrix
  module FreeSpinBonuses
    class BaseRequestHandler < ApplicationService
      def initialize(free_spin_bonus_wallet:)
        @free_spin_bonus_wallet = free_spin_bonus_wallet
      end

      private

      attr_reader :free_spin_bonus_wallet

      def result
        @result ||= request_result
      end

      def request_result
        request_result = HTTParty.post(
          url,
          body: body.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

        log_request(
          level: :info,
          url: url,
          request_body: body,
          response_body: request_result
        )

        request_result
      end

      def log_request(level:, url:, request_body:, response_body:)
        Rails.logger.send(level,
                          message: 'EveryMatrix Vendor Bonus API request',
                          url: url,
                          params: request_body,
                          response: response_body)
      end

      def domain_id
        ENV['EVERY_MATRIX_DOMAIN_ID']
      end

      def vendor
        @vendor ||= free_spin_bonus.vendor
      end

      def free_spin_bonus
        @free_spin_bonus ||= free_spin_bonus_wallet.free_spin_bonus
      end

      def wallet
        @wallet ||= free_spin_bonus_wallet.wallet
      end

      def update_last_request(name:, body:, result:)
        free_spin_bonus_wallet.update_attributes(
          last_request_name: name,
          last_request_body: body.to_json,
          last_request_result: result.to_json
        )
      end
    end
  end
end
