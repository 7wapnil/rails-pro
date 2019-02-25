# frozen_string_literal: true

describe EntryRequests::Factories::Refund do
  subject(:service) { described_class.new(entry: entry, **attributes) }

  let(:entry) { create(:entry) }
  let(:bonus_balance_entry) { create(:balance_entry, :bonus, entry: entry) }
  let(:refund_comment) { Faker::Lorem.sentence }
  let(:created_request) { service.call }
  let(:created_balance_requests) { created_request.balance_entry_requests }
  let(:attributes) do
    {
      comment: refund_comment
    }
  end

  context 'success' do
    it 'returns entry request' do
      expect(created_request).to be_instance_of(EntryRequest)
    end

    it 'assigns correct attributes' do
      assigned_attributes = {
        amount: entry.amount,
        currency: entry.currency,
        customer: entry.customer,
        kind: EntryRequest::REFUND,
        origin: entry
      }

      expect(created_request).to have_attributes(assigned_attributes)
    end

    context 'balance entry requests creation' do
      let(:real_balance) { create(:balance, :real_money, wallet: entry.wallet) }
      let(:bonus_balance) { create(:balance, :bonus, wallet: entry.wallet) }
      let!(:real_balance_entry) do
        create(:balance_entry, entry: entry, balance: real_balance)
      end
      let!(:bonus_balance_entry) do
        create(:balance_entry, entry: entry, balance: bonus_balance)
      end

      before do
        allow(BalanceRequestBuilders::Refund)
          .to receive(:call)
          .and_call_original
      end

      it 'calls BalanceRequestBuilders::Refund with correct arguments' do
        refund_amounts = {
          real_money: real_balance_entry.amount,
          bonus: bonus_balance_entry.amount
        }

        expect(BalanceRequestBuilders::Refund)
          .to have_received(:call)
          .with(created_request, refund_amounts)
      end

      it 'creates correct amount of balance entry requests' do
        expect(created_balance_requests.length).to eq(2)
      end
    end
  end
end
