# frozen_string_literal: true

shared_context 'successful_deposit_response' do
  let(:customer) { create(:customer) }
  let(:amount) { rand(10..100) }
  let(:currency_code) { wallet&.currency&.code }
  let(:status) { 'confirmed' }
  let!(:wallet) do
    create(:wallet, :crypto, :with_crypto_address, customer: customer)
  end

  let(:response) do
    {
      id: Faker::Number.number(5),
      crypto_address: {
        currency: currency_code,
        foreign_id: customer.id,
      },
      currency_received: {
        amount: amount
      },
      type: 'deposit',
      status: status
    }.to_json
  end
end
