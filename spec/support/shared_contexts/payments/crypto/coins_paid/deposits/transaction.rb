# frozen_string_literal: true

shared_context 'crypto_deposit_transaction' do
  let(:customer) { create(:customer) }
  let(:bonus_code) { nil }
  let(:method) { Payments::Methods::BITCOIN }
  let(:amount) { rand(10..100) }
  let(:currency_code) { wallet&.currency&.code }
  let!(:wallet) do
    create(:wallet, :crypto, :with_crypto_address, customer: customer)
  end

  let(:transaction) do
    ::Payments::Transactions::Deposit.new(
      method: method,
      customer: customer,
      currency_code: currency_code,
      amount: amount,
      bonus_code: bonus_code
    )
  end
end
