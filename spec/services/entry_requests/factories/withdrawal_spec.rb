# frozen_string_literal: true

describe EntryRequests::Factories::Withdrawal do
  subject(:service) do
    described_class.new(
      transaction: transaction
    )
  end

  let(:initiator) { create(:user) }

  let(:transaction) do
    ::Payments::Transactions::Withdrawal.new(
      customer: wallet.customer,
      currency_code: currency.code,
      amount: withdraw_amount,
      method: EntryRequest::BITCOIN,
      initiator: initiator
    )
  end
  let(:withdraw_amount) { 50 }
  let(:currency) { create(:currency, :with_withdrawal_rule) }
  let(:wallet) { create(:wallet, currency: currency, real_money_balance: 100) }

  context 'when success' do
    let(:created_request) { service.call }
    let(:expected_attrs) do
      {
        amount: -withdraw_amount,
        currency_id: wallet.currency_id,
        customer_id: wallet.customer_id,
        mode: EntryRequest::BITCOIN
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

      service.call
    end
  end

  context 'with errors' do
    let(:entry_request) { create(:entry_request) }
    let(:initiator) { entry_request.customer }
    let(:error_message) { "can't be blank" }
    let(:error_attribute) { :password }

    before do
      allow(EntryRequest).to receive(:create!).and_return(entry_request)
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
