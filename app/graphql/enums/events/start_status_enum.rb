# frozen_string_literal: true

module Events
  class StartStatusEnum < Base::Enum
    description 'Event start status'

    value Event::UPCOMING, 'Upcoming'
    value Event::LIVE, 'Live'
  end
end
