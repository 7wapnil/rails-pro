# frozen_string_literal: true

module Em
  module Requests
    class BaseRequestService < ApplicationService
      protected

      def common_response
        {
          'ApiVersion' => '1.0',
          'Request'    => request_name
        }
      end

      def common_success_response
        common_response.merge(
          'ReturnCode' => '0',
          'Message'    => 'Success'
        )
      end

      def user_not_found_response
        common_response.merge(
          'ReturnCode' => '103',
          'Message'    => 'User not found'
        )
      end

      def currency_code
        wallet.currency.code
      end
    end
  end
end
