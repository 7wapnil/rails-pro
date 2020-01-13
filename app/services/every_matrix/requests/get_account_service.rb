# frozen_string_literal: true

module EveryMatrix
  module Requests
    class GetAccountService < SessionRequestService
      include CurrencyDenomination

      def call
        return user_not_found_response unless customer

        success_response
      end

      private

      def request_name
        'GetAccount'
      end

      def country_code
        ip_lookup || profile_country
      end

      def ip_lookup
        country_code = Geocoder.search(customer.current_sign_in_ip&.to_string)
                               .first
                               &.data
                               &.fetch('country')

        ISO3166::Country.new(country_code)&.alpha3
      end

      def profile_country
        ISO3166::Country.find_country_by_name(customer.address.country).alpha3
      end

      def birthdate
        customer.date_of_birth.iso8601
      end

      def success_response
        common_success_response.merge(
          'SessionId' => session.id,
          'AccountId' => wallet.id.to_s,
          'Country'   => country_code,
          'City'      => customer.address.city,
          'Currency'  => response_currency_code,
          'UserName'  => customer.username,
          'FirstName' => customer.first_name,
          'LastName'  => customer.last_name,
          'Birthdate' => birthdate
        )
      end

      def response_currency_code
        denominate_currency_code(code: currency_code)
      end
    end
  end
end
