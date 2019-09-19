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
    end
  end
end
