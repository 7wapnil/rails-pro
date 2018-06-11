module EntryKinds
  extend ActiveSupport::Concern

  KINDS = {
    deposit: 0,
    win: 1,
    internal: 2,
    withdraw: 3,
    bet: 4
  }.freeze

  FUND_KINDS = KINDS.slice(:deposit, :internal, :withdraw)

  TRADING_KINDS = KINDS.slice(:win, :bet)

  included do
    enum kind: KINDS
  end
end
