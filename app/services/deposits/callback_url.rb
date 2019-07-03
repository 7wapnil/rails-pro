module Deposits
  class CallbackUrl
    REQUEST_FAILED_MESSAGE =
      I18n.t('errors.messages.deposit_failed')
    REQUEST_MESSAGE_CANCELLED_MESSAGE =
      I18n.t('errors.messages.deposit_cancelled')
    SOMETHING_WENT_WRONG_MESSAGE =
      I18n.t('errors.messages.technical_error_happened')
    FAILED_ENTRY_REQUEST_MESSAGE =
      I18n.t('errors.messages.deposit_attempt_is_not_succeded')
    DEPOSIT_ATTEMPTS_EXCEEDED_MESSAGE =
      I18n.t('errors.messages.deposit_attempts_exceeded')

    SUCCESS = :success
    PENDING = :pending
    BACK = :back
    ERROR = :error
    SOMETHING_WENT_WRONG = :something_went_wrong
    FAILED_ENTRY_REQUEST = :failed_entry_request
    DEPOSIT_ATTEMPTS_EXCEEDED = :deposit_attempts_exceeded

    CALLBACK_OPTIONS = {
      SUCCESS => { kind: :success },
      PENDING => { kind: :pending },
      ERROR => { kind: :fail, message: REQUEST_FAILED_MESSAGE },
      BACK =>
        { kind: :fail, message: REQUEST_MESSAGE_CANCELLED_MESSAGE },
      SOMETHING_WENT_WRONG =>
        { kind: :fail, message: SOMETHING_WENT_WRONG_MESSAGE },
      FAILED_ENTRY_REQUEST =>
        { kind: :fail, message: FAILED_ENTRY_REQUEST_MESSAGE },
      DEPOSIT_ATTEMPTS_EXCEEDED =>
        { kind: :fail, message: DEPOSIT_ATTEMPTS_EXCEEDED_MESSAGE }
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
