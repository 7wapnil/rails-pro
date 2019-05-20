module Payments
  class BaseProvider
    def deposit!(_transaction)
      # create initial entry request
      # validate transaction and check business rules
      # initiate deposit
    end
  end
end
