# frozen_string_literal: true

describe CustomerBonuses::Deactivate do
  let(:customer_bonus) { create(:customer_bonus) }

  include_context 'frozen_time'

  context 'with active customer bonus' do
    let!(:bonus_balance) { create(:balance, :bonus, wallet: wallet) }
    let(:wallet) { customer_bonus.wallet }

    let(:found_entry_request) do
      EntryRequest.bonus_change.find_by(origin: customer_bonus)
    end
    let(:comment) do
      "Bonus transaction: #{-bonus_balance.amount} #{wallet.currency} " \
      "for #{wallet.customer}."
    end

    before do
      allow(EntryRequests::BonusChangeWorker).to receive(:perform_async)
      described_class.call(
        bonus: customer_bonus,
        action: CustomerBonuses::Deactivate::CANCEL
      )
    end

    it 'creates bonus change entry request' do
      expect(found_entry_request).to have_attributes(
        mode: EntryRequest::INTERNAL,
        amount: -bonus_balance.amount,
        comment: comment,
        customer: wallet.customer,
        currency: wallet.currency
      )
    end

    it 'schedules job for updating wallet' do
      expect(EntryRequests::BonusChangeWorker)
        .to have_received(:perform_async)
        .with(found_entry_request.id)
    end
  end
end
