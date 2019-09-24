# frozen_string_literal: true

describe EntryRequests::Factories::Refund do
  subject(:service) { described_class.new(entry: entry, **attributes) }

  let(:entry) { create(:entry) }
  let(:refund_comment) { Faker::Lorem.sentence }
  let(:entry_request) { service.call }
  let(:attributes) do
    {
      comment: refund_comment
    }
  end

  context 'success' do
    it 'returns entry request' do
      expect(entry_request).to be_instance_of(EntryRequest)
    end

    it 'assigns correct attributes' do
      assigned_attributes = {
        amount: entry.amount,
        currency: entry.currency,
        customer: entry.customer,
        kind: EntryRequest::REFUND,
        origin: entry.origin
      }

      expect(entry_request).to have_attributes(assigned_attributes)
    end

    context 'entry requests creation' do
      let(:real_money_balance) { 100 }
      let(:bonus_balance) { 20 }
      let!(:update_entry_balance) do
        entry.update(
          real_money_amount: real_money_balance,
          bonus_amount: bonus_balance
        )
      end

      it 'creates entry request with correct balance attributes' do
        refund_amounts = {
          real_money_amount: real_money_balance,
          bonus_amount: bonus_balance
        }

        expect(entry_request).to have_attributes(refund_amounts)
      end
    end
  end
end
