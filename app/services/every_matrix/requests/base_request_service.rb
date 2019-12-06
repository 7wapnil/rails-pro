# frozen_string_literal: true

module EveryMatrix
  module Requests
    class BaseRequestService < ApplicationService
      include ErrorCodes

      def initialize(params)
        @params = params
      end

      protected

      attr_reader :params

      def common_response
        {
          'ApiVersion' => '1.0',
          'Request'    => request_name
        }
      end

      def common_success_response
        common_response.merge(
          'ReturnCode' => SUCCESS_CODE,
          'Message'    => SUCCESS_MESSAGE
        )
      end

      def request_name
        error_msg = "#{__method__} needs to be implemented in #{self.class}"

        raise NotImplementedError, error_msg
      end
    end
  end
end
