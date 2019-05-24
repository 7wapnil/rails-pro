module Payments
  class BaseProvider
    def payment_page_url(transaction)
      raise ::NotImplementedError
    end

    def handle_success
      raise ::NotImplementedError
    end

    def handle_fail
      raise ::NotImplementedError
    end

    def handle_cancel
      raise ::NotImplementedError
    end
  end
end
