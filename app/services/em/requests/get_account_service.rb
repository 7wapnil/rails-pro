# frozen_string_literal: true

module Em
  module Requests
    class GetAccountService < BaseRequestService
      def initialize(params)
        @session_id = params.permit('SessionId')['SessionId']
        @session = Em::WalletSession.find_by(id: @session_id)
        @customer = @session&.customer
      end

      def call
        return user_not_found_response unless @customer

        success_response
      end

      protected

      def request_name
        'GetAccount'
      end

      private

      attr_reader :customer, :session_id

      def country_code
        ISO3166::Country.find_country_by_name(customer.address.country).alpha3
      end

      def currency_code
        customer.wallet.currency.code
      end

      def birthdate
        customer.date_of_birth.iso8601
      end

      def success_response
        common_success_response.merge(
          'SessionId' => session_id,
          'AccountId' => customer.id,
          'Country'   => country_code,
          'City'      => customer.address.city,
          'Currency'  => currency_code,
          'UserName'  => customer.username,
          'FirstName' => customer.first_name,
          'LastName'  => customer.last_name,
          'Birthdate' => birthdate
        )
      end

      def user_not_found_response
        common_response.merge(
          'ReturnCode' => '103',
          'Message'    => 'User not found'
        )
      end
    end
  end
end
