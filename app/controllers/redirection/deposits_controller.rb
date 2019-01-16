module Redirection
  class DepositsController < ActionController::Base
    def initiate
      redirect_to ENV['SAFECHARGE_HOSTED_PAYMENTS_URL']
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
      redirect_to ENV['FRONTEND_URL'] + '?state=' + state
    end
  end
end
