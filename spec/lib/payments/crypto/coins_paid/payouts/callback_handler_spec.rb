# frozen_string_literal: true

describe Payments::Crypto::CoinsPaid::Payouts::CallbackHandler do
  subject { described_class.call(JSON.parse(request)) }

  let(:request) do
    <<-EXAMPLE_JSON
        {
          "id": 1,
          "foreign_id": "#{withdraw.id}",
          "type": "withdrawal",
          "currency_sent": {
            "currency": "BTC",
            "amount": "0.02000000"
          },
          "currency_received": {
            "currency": "BTC",
            "amount": "0.02000000"
          },
          "transactions": [
            {
              "id": #{transaction_id},
              "currency": "BTC",
              "transaction_type": "blockchain",
              "type": "withdrawal",
              "address": "115Mn1jCjBh1CNqug7yAB21Hq2rw8PfmTA",
              "tag": null,
              "amount": "0.02",
              "confirmations": 3
            }
          ],
          "error": "#{error_message}",
          "status": "#{status}"
        }
    EXAMPLE_JSON
  end

  let!(:customer) { create(:customer) }
  let!(:wallet) do
    create(:wallet, :crypto_btc, :with_crypto_address, customer: customer)
  end
  let(:error_message) { Faker::Lorem.sentence }
  let!(:withdraw) do
    create(:entry_request, :withdraw,
           customer: customer,
           currency: wallet.currency)
  end
  let!(:withdrawal) do
    create(:withdrawal, entry_request: withdraw)
  end
  let(:transaction_id) { rand(1..5) }

  context 'succeeded' do
    let(:status) { Payments::Crypto::CoinsPaid::Statuses::CONFIRMED }

    it 'succeeds withdrawal' do
      subject

      expect(withdrawal.reload.status).to eq(Withdrawal::SUCCEEDED)
    end

    it 'updates entry request with external_id' do
      subject

      expect(withdraw.reload.external_id).to eq(transaction_id.to_s)
    end
  end

  context 'cancelled' do
    let(:status) { Payments::Crypto::CoinsPaid::Statuses::CANCELLED }

    it 'updates entry request' do
      expect_any_instance_of(Withdrawal)
        .to receive(:update!).with(status: Withdrawal::PENDING,
                                   transaction_message: error_message)

      subject
    end
  end
end
