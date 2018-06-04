module EntryTypes
  extend ActiveSupport::Concern

  included do
    enum type: {
      deposit: 0,
      winning: 1,
      internal_debit: 2,
      withdraw: 3,
      bet: 4,
      internal_credit: 5
    }
  end
end
