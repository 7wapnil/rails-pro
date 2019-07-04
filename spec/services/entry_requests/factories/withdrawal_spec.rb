# frozen_string_literal: true

describe EntryRequests::Factories::Withdrawal do
  subject(:service) do
    described_class.new(transaction: transaction)
  end

  let(:transaction) do
    ::Payments::Transactions::Withdrawal.new(
      customer: wallet.customer,
      currency_code: currency.code,
      amount: withdraw_amount,
      method: EntryRequest::CASHIER
    )
  end
  let(:withdraw_amount) { 50 }
  let(:currency) { create(:currency, :with_withdrawal_rule) }
  let(:wallet) { create(:wallet, currency: currency) }
  let!(:balance) do
    create(:balance, :real_money, amount: 100, wallet: wallet)
  end

  context 'when success' do
    let(:created_request) { service.call }
    let(:expected_attrs) do
      {
        amount: -withdraw_amount,
        currency_id: wallet.currency_id,
        customer_id: wallet.customer_id,
        mode: EntryRequest::CASHIER
      }
    end

    it 'returns created entry request' do
      expect(created_request).to be_instance_of(EntryRequest)
    end

    it 'assigns correct entry request attributes' do
      assigned_attrs = created_request
                       .slice(:amount, :currency_id, :customer_id, :mode)
                       .symbolize_keys

      expect(assigned_attrs).to eq(expected_attrs)
    end

    it 'build balance entry requests' do
      entry_request = create(:entry_request)
      allow(EntryRequest).to receive(:create!).and_return(entry_request)

      expect(BalanceRequestBuilders::Withdrawal)
        .to receive(:call)
        .with(entry_request, real_money: -withdraw_amount)

      service.call
    end
  end

  context 'with errors' do
    let(:entry_request) { create(:entry_request) }
    let(:error_message) { Faker::Lorem.sentence }
    let(:error_attribute) { :password }
    let(:form) do
      instance_double(::Payments::Withdrawals::CreateForm.name,
                      errors: { error_attribute => error_message })
    end

    before do
      allow(EntryRequest).to receive(:create!).and_return(entry_request)
      allow(::Payments::Withdrawals::CreateForm)
        .to receive(:new)
        .and_return(form)
      allow(form)
        .to receive(:validate!)
        .and_raise(ActiveModel::ValidationError, EntryRequest.new)
      allow(entry_request).to receive(:register_failure!)
    end

    it 'register entry request withdrawal error' do
      service.call

      expect(entry_request)
        .to have_received(:register_failure!)
        .with(error_message, error_attribute)
    end
  end
end
