# frozen_string_literal: true

describe Customers::AvailableDepositMethods do
  subject { described_class.call(customer: customer) }

  let(:customer) { create(:customer) }
  let(:currency) { create(:currency) }
  let!(:wallet) do
    create(:wallet, customer: customer, currency: currency)
  end
  let!(:deposit_rule) do
    create(:entry_currency_rule, :deposit, currency: currency)
  end
  let(:limits) { deposit_rule.slice(:min_amount, :max_amount) }

  let(:mode) { nil }
  let(:payment_method) { subject.find { |method| method.name == mode } }

  context 'credit card' do
    let(:mode) { ::Payments::Methods::CREDIT_CARD }

    it 'returns correct max and min amount' do
      expect(payment_method).to have_attributes(limits)
    end
  end

  context 'unsupported country' do
    let(:mode) { ::Payments::Methods::PAYSAFECARD }
    let!(:address) { create(:address, customer: customer, country: 'Iraq') }

    it 'rejects payment method' do
      expect(payment_method).to be_nil
    end
  end

  context 'bitcoin without crypto wallet' do
    let(:mode) { ::Payments::Methods::BITCOIN }
    let(:code) { ::Payments::Crypto::CoinsPaid::Currency::MBTC_CODE }
    let(:crypto_currency) { create(:currency, :crypto, code: code) }
    let!(:deposit_rule) do
      create(:entry_currency_rule, :deposit, currency: crypto_currency)
    end

    it 'does not create crypto wallet' do
      expect(customer.currencies).not_to include(crypto_currency)
    end

    it 'returns correct max and min amount' do
      expect(payment_method).to have_attributes(limits)
    end
  end
end
