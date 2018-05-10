FactoryBot.define do # rubocop:disable Metrics/BlockLength
  factory :discipline do
    name 'CS:GO'
    kind :esports
  end

  factory :event_scope do
    discipline
    name 'FPSThailand CS:GO Pro League Season#4'
    kind :tournament
  end

  factory :scoped_event do
    event_scope
    event
  end

  factory :event do
    discipline
    name 'MiTH vs. Beyond eSports'
    description 'FPSThailand CS:GO Pro League Season#4 | MiTH vs. Beyond eSports' # rubocop:disable Metrics/LineLength
    start_at { 2.hours.ago }
    end_at { 1.hours.ago }
  end

  factory :market do
    event
    name 'Winner Map (Train)'
    priority 2
  end

  factory :odd do
    market
    name 'MiTH'
    won true
  end

  factory :odd_value do
    odd
    value 1.85
  end
end
