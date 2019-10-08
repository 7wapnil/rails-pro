# frozen_string_literal: true

module EveryMatrix
  module Requests
    class GetAccountService < SessionRequestService
      def call
        return user_not_found_response unless customer

        success_response
      end

      protected

      def request_name
        'GetAccount'
      end

      private

      def country_code
        ISO3166::Country.find_country_by_name(customer.address.country).alpha3
      end

      def birthdate
        customer.date_of_birth.iso8601
      end

      def success_response
        common_success_response.merge(
          'SessionId' => session.id,
          'AccountId' => customer.id.to_s,
          'Country'   => country_code,
          'City'      => customer.address.city,
          'Currency'  => currency_code,
          'UserName'  => customer.username,
          'FirstName' => customer.first_name,
          'LastName'  => customer.last_name,
          'Birthdate' => birthdate
        )
      end
    end
  end
end
