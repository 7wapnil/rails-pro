# frozen_string_literal: true

module Events
  class MarketStatusEnum < Base::Enum
    description 'Market status'

    value OddsFeed::Radar::MarketStatus::ACTIVE, 'Active'
    value OddsFeed::Radar::MarketStatus::INACTIVE, 'Inactive'
    value OddsFeed::Radar::MarketStatus::SUSPENDED, 'Suspended'
    value OddsFeed::Radar::MarketStatus::HANDED_OVER, 'Handed over'
    value OddsFeed::Radar::MarketStatus::SETTLED, 'Settled'
    value OddsFeed::Radar::MarketStatus::CANCELLED, 'Cancelled'
  end
end
