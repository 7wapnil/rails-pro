FactoryBot.define do # rubocop:disable Metrics/BlockLength
  factory :discipline do
    name 'CS:GO'
    kind 'esports'
  end

  factory :event do
    discipline
    event
    name 'MiTH vs. Beyond eSports'
    kind 'match'
    description 'FPSThailand CS:GO Pro League Season#4 | MiTH vs. Beyond eSports' # rubocop:disable Metrics/LineLength
    started_at { 2.hours.ago }
    ended_at { 1.hours.ago }
  end

  factory :market do
    event
    name 'Winner Map (Train)'
  end

  factory :odd do
    market
    name 'MiTH'
    won true
  end

  factory :odd_value do
    odd
    value 1.85
    active true
  end
end
