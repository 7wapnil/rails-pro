module Redirection
  class DepositsController < ActionController::Base
    def initiate
      redirect_url = ENV['SAFECHARGE_HOSTED_PAYMENTS_URL']
      render body: 'NotImplemented: Redirect to Safecharge: ' + redirect_url
    end

    def success
      callback(:success)
    end

    def error
      callback(:error)
    end

    def pending
      callback(:pending)
    end

    def back
      callback(:back)
    end

    def webhook
      head :ok
    end

    private

    def callback(state)
      redirect_url = ENV['FRONTEND_URL'] + '?state=' + state.to_s
      render body: redirect_url
    end
  end
end
