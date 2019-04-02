# frozen_string_literal: true

FactoryBot.define do
  factory :withdrawal_request do
    association :entry_request, :withdraw, :with_entry, strategy: :build
    status { WithdrawalRequest::PENDING }

    trait :rejected do
      status { WithdrawalRequest::REJECTED }
      actioned_by { create(:admin_user) }
    end

    trait :approved do
      status { WithdrawalRequest::APPROVED }
      actioned_by { create(:admin_user) }
    end
  end
end
