# frozen_string_literal: true

FactoryBot.define do
  factory :comment do
    text             { 'MyText' }
    commentable_id   { 1 }
    commentable_type { VerificationDocument.name }

    belongs_to       { user }
  end
end
