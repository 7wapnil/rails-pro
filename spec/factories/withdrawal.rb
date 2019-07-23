# frozen_string_literal: true

FactoryBot.define do
  factory :withdrawal, class: 'Withdrawal', parent: :customer_transaction do
    association :entry_request, :withdraw, :with_entry, strategy: :build
    type   { Withdrawal }
    status { Withdrawal::PENDING }

    trait :rejected do
      status { Withdrawal::REJECTED }
      actioned_by { create(:admin_user) }
    end

    trait :processing do
      status { Withdrawal::PROCESSING }
      actioned_by { create(:admin_user) }
    end

    trait :succeeded do
      status { Withdrawal::SUCCEEDED }
      actioned_by { create(:admin_user) }
    end
  end
end
