module EntryKinds
  extend ActiveSupport::Concern

  KINDS = {
    deposit: 0,
    winning: 1,
    internal_debit: 2,
    withdraw: 3,
    bet: 4,
    internal_credit: 5
  }

  included do
    enum kind: KINDS
  end
end
