# frozen_string_literal: true

module LoginActivities
  class TrackLogin
    def initialize(params)
      @customer = params[:customer]
      @identity = params[:identity]
      @request = params[:request]
    end

    def call(success:, failure_reason: nil)
      LoginActivity
        .create!(default_params.merge(success: success,
                                      failure_reason: failure_reason))
    end

    private

    attr_reader :customer, :identity, :request

    def default_params
      {
        scope: :customer,
        identity: identity,
        user: customer,
        context: 'customers#sign_in',
        ip: request.ip,
        user_agent: request.user_agent
      }
    end
  end
end
