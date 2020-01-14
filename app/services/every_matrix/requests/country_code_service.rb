# frozen_string_literal: true

module EveryMatrix
  module Requests
    class CountryCodeService < ApplicationService
      LOCAL_LOOKUP_PATH = %w[country iso_code].freeze
      EXTERNAL_LOOKUP_PATH = %w[country].freeze

      def initialize(customer:)
        @customer = customer
      end

      def call
        ip_lookup || profile_country
      end

      private

      attr_reader :customer

      def ip_lookup
        return country_code if country_code

        Rails.logger.warn message: 'Country lookup failed',
                          searched_country: searched_country,
                          customer_ip: ip,
                          customer_id: customer.id

        nil
      end

      def country_code
        @country_code ||= ISO3166::Country.new(searched_country)&.alpha3
      end

      def searched_country
        @searched_country ||=
          Geocoder.search(ip).first&.data&.dig(*lookup_path)
      end

      def ip
        customer.current_sign_in_ip&.to_string
      end

      def lookup_path
        Rails.env.production? ? LOCAL_LOOKUP_PATH : EXTERNAL_LOOKUP_PATH
      end

      def profile_country
        ISO3166::Country.find_country_by_name(customer.address.country).alpha3
      end
    end
  end
end
