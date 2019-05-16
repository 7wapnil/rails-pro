# frozen_string_literal: true

describe CustomerBonuses::Deactivate do
  let(:customer_bonus) { create(:customer_bonus) }

  include_context 'frozen_time'

  context 'with active customer bonus' do
    let!(:bonus_balance) { create(:balance, :bonus, wallet: wallet) }
    let(:wallet) { customer_bonus.wallet }

    let(:found_entry_request) do
      EntryRequest.bonus_change.find_by(origin: wallet)
    end
    let(:comment) do
      "Bonus transaction: #{-bonus_balance.amount} #{wallet.currency} " \
      "for #{wallet.customer}."
    end

    before do
      allow(EntryRequests::BonusChangeWorker).to receive(:perform_async)
      described_class.call(bonus: customer_bonus, action: :cancel!)
    end

    it 'removes customer bonus' do
      expect(customer_bonus.deleted_at).not_to be_nil
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

  context 'with already processed bonus' do
    let(:customer_bonus) do
      create(:customer_bonus, deleted_at: 5.hours.ago)
    end

    before do
      described_class.call(bonus: customer_bonus, action: :cancel!)
    end

    it 'does not override original expiration date' do
      expect(customer_bonus.deleted_at).to eq(5.hours.ago)
    end
  end
end
