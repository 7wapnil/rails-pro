# frozen_string_literal: true

module EveryMatrix
  module FreeSpinBonuses
    class CreateUserHandler < BaseRequestHandler
      DEFAULT_LANG = 'EN'
      DEFAULT_GENDER = 'Male'

      def call
        free_spin_bonus_wallet.send_to_create_user!
        update_status_on_result!
        update_last_request(name: 'CreateUser', body: body, result: result)

        result['Success']
      end

      private

      def update_status_on_result!
        return handle_user_created! if result['Success']

        free_spin_bonus_wallet.create_user_with_error!
      end

      def handle_user_created!
        free_spin_bonus_wallet.create_user!
        wallet.update_attribute(:every_matrix_user_id,
                                result['InternalUserId'])
      end

      def url
        ENV['EVERY_MATRIX_CREATE_USER_URL']
      end

      def body
        # EXAMPLE
        # {
        #   "DomainId": 1681,
        #   "CountryAlpha3Code": "UKR",
        #   "Gender": "Male",
        #   "Alias": "ekovalenko",
        #   "City": "Lviv",
        #   "Lang": "UA",
        #   "Currency": "EUR",
        #   "FirstName": "Evgen",
        #   "LastName": "Kovalenko",
        #   "OperatorUserId": "201801111140"
        # }

        {
          "DomainId": domain_id,
          "CountryAlpha3Code": country_code,
          "Gender": gender,
          "Alias": customer.username,
          "City": address.city,
          "Lang": DEFAULT_LANG,
          "Currency": wallet.currency.code,
          "FirstName": customer.first_name,
          "LastName": customer.last_name,
          "OperatorUserId": wallet.id
        }
      end

      def customer
        @customer ||= wallet.customer
      end

      def address
        @address ||= customer.address
      end

      def country_code
        ISO3166::Country.find_country_by_name(address.country).alpha3
      end

      def gender
        @gender ||= customer.gender&.capitalize || DEFAULT_GENDER
      end
    end
  end
end
