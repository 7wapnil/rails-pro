# frozen_string_literal: true

describe Payments::Crypto::CoinsPaid::CallbackHandler do
  subject { described_class.call(request_double) }

  let(:request_double) { double }

  before do
    create(:currency, :primary)
    allow(request_double).to receive(:body).and_return(request_double)
    allow(request_double).to receive(:string).and_return(request)
  end

  context 'deposit callback' do
    let(:request) do
      <<-EXAMPLE_JSON
      {
        "id": #{transaction_id},
        "type": "deposit",
        "crypto_address": {
          "id": 1,
          "currency": "BTC",
          "address": "39mFf3X46YzUtfdwVQpYXPCMydc74ccbAZ",
          "foreign_id": "#{customer.id}",
          "tag": null
        },
        "currency_received": {
          "currency": "BTC",
          "amount": "#{deposit_amount}",
          "amount_minus_fee": "6.5119800"
        },
        "error": "",
        "status": "#{status}"
      }
      EXAMPLE_JSON
    end

    let(:transaction_id) { rand(1..5) }
    let!(:customer) { create(:customer) }
    let(:deposit_amount) { rand(1..10) }
    let(:status) { Payments::Crypto::CoinsPaid::Statuses::CONFIRMED }
    let!(:wallet) do
      create(:wallet, :crypto_btc, :with_crypto_address,
      customer: customer,
      amount: 0)
    end

    it 'chooses correct handler' do
      expect(::Payments::Crypto::CoinsPaid::Deposits::CallbackHandler)
        .to receive(:call)

      subject
    end

    context 'confirmed transaction' do
      it 'creates entries' do
        expect{ subject }.to change(Entry, :count)
      end

      it 'changes customer balance' do
        subject

        expect(wallet.reload.amount).to eq((deposit_amount.to_d * 1000).round(2))
      end

      context 'with active bonus' do
        let!(:customer_bonus) do
          create(:customer_bonus, :initial,
                 customer: customer,
                 wallet: wallet,
                 percentage: 100,
                 original_bonus: bonus)
        end
        let!(:bonus) { create(:bonus, max_deposit_match: 9999999) }

        it 'gives bonus on deposit' do
          subject

          expect(wallet.reload.amount)
            .to eq((deposit_amount.to_d * 1000 * 2).round(2))
        end

        it 'activates customer bonus' do
          subject

          expect(customer_bonus.reload.status).to eq(CustomerBonus::ACTIVE)
        end
      end
    end

    context 'cancelled transaction' do
      let(:status) { Payments::Crypto::CoinsPaid::Statuses::CANCELLED }

      it 'creates entry request' do
        expect{ subject }.to change(EntryRequest, :count)
      end

      it 'does not change customer balance' do
        subject

        expect(wallet.reload.amount).to eq(0)
      end

      it 'fails entry request' do
        expect_any_instance_of(EntryRequest).to receive(:register_failure!)

        subject
      end
    end

    context 'unprocessable statuses' do
      context 'pending transaction' do
        let(:status) { Payments::Crypto::CoinsPaid::Statuses::NOT_CONFIRMED }

        it 'does not create entries' do
          expect(EntryRequests::Factories::Deposit).not_to receive(:call)

          subject
        end

        it 'does not change customer balance' do
          subject

          expect(wallet.reload.amount).to eq(0)
        end
      end

      context 'already proceeded transaction' do
        let(:status) { 'confirmed' }
        let(:transaction) do
          create(:entry_request, :deposit,
                 customer: customer,
                 currency: wallet.currency,
                 mode: 'bitcoin',
                 external_id: Faker::Number.number(6))
        end
        let(:transaction_id) { transaction.external_id }

        it 'chooses correct handler' do
          expect(::Payments::Crypto::CoinsPaid::Deposits::CallbackHandler)
            .to receive(:call)

          subject
        end

        it 'does not create entries' do
          expect(EntryRequests::Factories::Deposit).not_to receive(:call)

          subject
        end

        it 'does not change customer balance' do
          subject

          expect(wallet.reload.amount).to eq(0)
        end
      end
    end

    context 'unknown status' do
      let(:status) { Faker::Lorem.word }

      it 'creates entry request' do
        expect{ subject }.to change(EntryRequest, :count)

      rescue ::Payments::GatewayError
      end

      it 'fails entry request' do
        expect_any_instance_of(EntryRequest).to receive(:register_failure!)

        subject
      rescue ::Payments::GatewayError
      end

      it 'raises error' do
        expect{ subject }.to raise_error(::Payments::GatewayError)
      end
    end
  end

  context 'withdraw callback' do
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
              "txid": "bb040d895ef7141ea0b06b04227d8f5dd4ee12d5b890e6e5633f6439393a666b",
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
             currency: wallet.currency,
             external_id: Faker::Number.number(6))
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

      it 'updates entry request external_id' do
        subject

        expect(withdraw.reload.external_id).to eq(transaction_id.to_s)
      end
    end

    context 'cancelled' do
      let(:status) { Payments::Crypto::CoinsPaid::Statuses::CANCELLED }

      it 'updates withdrawal status' do
        subject

        expect(withdrawal.reload.status).to eq(Withdrawal::PENDING)
      end
    end
  end

  context 'unknown payment type' do
    let(:request) do
      <<-EXAMPLE_JSON
        { 
          "status": "#{Faker::Lorem.word}"
        }
      EXAMPLE_JSON
    end

    it 'raises error' do
      expect{ subject }.to raise_error(::Payments::GatewayError)
    end
  end
end
