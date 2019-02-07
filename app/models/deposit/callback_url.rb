module Deposit
  class CallbackUrl
    REQUEST_FAILED_MESSAGE = 'Deposit request failed'.freeze
    REQUEST_MESSAGE_CANCELLED_MESSAGE = 'Deposit request cancelled'.freeze
    SOMETHING_WENT_WRONG = 'Technical error happened'.freeze
    FAILED_ENTRY_REQUEST = 'Deposit is not allowed'.freeze
    ATTEMPTS_EXCEEDED = I18n.t('errors.messages.deposit_attempts_exceeded')

    CALLBACK_OPTIONS = {
      success: { kind: :success },
      pending: { kind: :pending },
      error: { kind: :fail, message: REQUEST_FAILED_MESSAGE },
      back: { kind: :fail, message: REQUEST_MESSAGE_CANCELLED_MESSAGE },
      something_went_wrong: { kind: :fail, message: SOMETHING_WENT_WRONG },
      failed_entry_request: { kind: :fail, message: FAILED_ENTRY_REQUEST },
      deposit_attempts_exceeded: { kind: :fail, message: ATTEMPTS_EXCEEDED }
    }.freeze

    def self.for(state, message: nil)
      new(state: state, message: message).url
    end

    def initialize(state:, message: nil)
      @state = state
      @message = message || url_data[:message]
    end

    def url
      URI(ENV['FRONTEND_URL']).tap do |uri|
        uri.query =
          { depositState: url_data[:kind],
            depositStateMessage: @message }.compact.to_query
      end.to_s
    end

    private

    def url_data
      @url_data ||= CALLBACK_OPTIONS[@state]
    end
  end
end
