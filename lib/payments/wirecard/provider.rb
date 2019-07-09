# frozen_string_literal: true

module Payments
  module Wirecard
    class Provider < ::Payments::BaseProvider
      def payment_page_url(transaction)
        ::Payments::Wirecard::Deposits::RequestHandler
          .call(transaction: transaction, client: client)
      end

      def deposit_response_handler
        ::Payments::Wirecard::Deposits::CallbackHandler
      end

      def client
        @client ||= Client.new
      end
    end
  end
end
