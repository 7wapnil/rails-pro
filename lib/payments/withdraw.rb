# Part of code copied from old Mihail's solution and looks like not the best
# one.
# On execution entry request (initial or failed) are not saved, but must be!
# So, I propose to update this code with following order:
#
# - Create initial request (status initial)
# - Validate transaction
# -- If invalid or error raised update request to FAILED with result message
# - return payment page url
#
#
# Validation of business rules (deposit amount limit, attempts) moved to
# Transaction
#
module Payments
  class Withdraw < Operation
    include Methods

    PAYMENT_METHODS = [
      ::Payments::Methods::CREDIT_CARD,
      ::Payments::Methods::NETELLER,
      ::Payments::Methods::SKRILL,
      ::Payments::Methods::BITCOIN
    ].freeze
  end
end
