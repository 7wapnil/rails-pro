# frozen_string_literal: true

describe Payments::Crypto::CoinsPaid::Deposits::CallbackHandler do
  subject { described_class.call(response) }

  let(:response) do
    JSON.parse(
      file_fixture('payments/crypto/coins_paid/deposits/response.json').read
    )
  end

  let(:customer) { create(:customer) }
  let(:bonus_code) { nil }
  let(:amount) { rand(10..100) }
  let(:currency_code) { wallet&.currency&.code }
  let!(:wallet) do
    create(:wallet, :crypto_btc, :with_crypto_address, customer: customer)
  end
  let(:entry_request) do
    create(:entry_request, :deposit, customer: customer, currency: wallet.currency)
  end

  before do
    response['crypto_address']['foreign_id'] = customer.id
    response['status'] = status
  end

  context 'not proceeded transaction' do
    context 'response status confirmed' do
      let(:status) { Payments::Crypto::CoinsPaid::Statuses::CONFIRMED }
      let(:entry_request_double) { double }

      it 'calls entry request creation' do
        allow(entry_request_double).to receive(:succeeded?).and_return(true)
        allow(entry_request_double).to receive(:origin).and_return(nil)

        expect(::EntryRequests::Factories::Deposit)
          .to receive(:call).and_return(entry_request_double)

        subject
      end

      it 'calls deposit service' do
        allow(entry_request_double).to receive(:succeeded?).and_return(false)

        expect(::EntryRequests::DepositService).to receive(:call)

        subject
      end
    end

    context 'response status cancelled' do
      let(:status) { Payments::Crypto::CoinsPaid::Statuses::CANCELLED }
      let(:entry_request_double) { double }
      let(:origin_double) { double }
      let(:customer_bonus_double) { double }
      let!(:customer_bonus) do
        create(:customer_bonus,
               :initial,
               customer: customer,
               wallet: wallet,
               min_deposit: 0)
      end

      it 'calls entry request creation' do
        allow(entry_request_double).to receive(:register_failure!)
        allow(entry_request_double).to receive(:origin).and_return(nil)

        expect(::EntryRequests::Factories::Deposit)
          .to receive(:call).and_return(entry_request_double)

        subject
      end

      it 'register failure' do
        allow(::EntryRequests::Factories::Deposit)
          .to receive(:call).and_return(entry_request_double)
        allow(entry_request_double).to receive(:origin).and_return(nil)

        expect(entry_request_double).to receive(:register_failure!)

        subject
      end

      it 'fails customer bonus' do
        allow(::EntryRequests::Factories::Deposit)
          .to receive(:call).and_return(entry_request_double)
        allow(entry_request_double).to receive(:register_failure!)
        allow(entry_request_double)
          .to receive(:origin).and_return(origin_double)
        allow(origin_double).to receive(:failed!)

        subject

        expect(customer_bonus.reload.failed?).to be(true)
      end

      it 'fails origin' do
        allow(::EntryRequests::Factories::Deposit)
          .to receive(:call).and_return(entry_request_double)
        allow(entry_request_double).to receive(:register_failure!)
        allow(entry_request_double)
          .to receive(:origin).and_return(origin_double)
        allow(origin_double)
          .to receive(:customer_bonus).and_return(customer_bonus_double)

        expect(origin_double).to receive(:failed!)

        subject
      end
    end
  end

  context 'pending status in response' do
    let(:status) { Payments::Crypto::CoinsPaid::Statuses::NOT_CONFIRMED }

    it 'does not call entry request creation' do
      expect(::EntryRequests::Factories::Deposit)
        .not_to receive(:call)

      subject
    end
  end

  context 'already proceeded transaction' do
    before do
      create(:entry_request, :deposit,
             external_id: response['id'],
             customer: customer,
             mode: EntryRequest::BITCOIN
      )
    end

    let(:status) { Payments::Crypto::CoinsPaid::Statuses::CONFIRMED }

    it 'does not call entry request creation' do
      expect(::EntryRequests::Factories::Deposit)
        .not_to receive(:call)

      subject
    end
  end

  context 'unknown response status' do
    let(:status) { Faker::Lorem.word }
    let(:entry_request_double) { double }

    it 'calls entry request creation' do
      allow(entry_request_double).to receive(:register_failure!)
      allow(entry_request_double).to receive(:id).and_return(rand(1..5))
      allow(entry_request_double).to receive(:origin).and_return(nil)

      expect(::EntryRequests::Factories::Deposit)
        .to receive(:call).and_return(entry_request_double)

      subject
    rescue ::Payments::GatewayError
    end

    it 'raises error' do
      allow(entry_request_double).to receive(:register_failure!)
      allow(entry_request_double).to receive(:origin).and_return(nil)

      expect{ subject }.to raise_error(::Payments::GatewayError)
    end

    it 'registers failure' do
      allow(::EntryRequests::Factories::Deposit)
        .to receive(:call).and_return(entry_request_double)
      allow(entry_request_double).to receive(:id).and_return(rand(1..5))
      allow(entry_request_double).to receive(:origin).and_return(nil)

      expect(entry_request_double).to receive(:register_failure!)

      subject
    rescue ::Payments::GatewayError
    end

    it 'failes customer bonus' do

    end
  end
end
