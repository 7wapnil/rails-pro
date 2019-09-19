# frozen_string_literal: true

FactoryBot.define do
  factory :em_wallet_session, class: Em::WalletSession.name do
    wallet
  end
end
