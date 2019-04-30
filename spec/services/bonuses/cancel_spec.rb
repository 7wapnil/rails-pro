# frozen_string_literal: true

describe Bonuses::Cancel do
  let(:expiration_reason) { CustomerBonus.expiration_reasons.keys.first }
  let(:another_expiration_reason) { CustomerBonus.expiration_reasons.keys.last }
  let(:customer_bonus) { create(:customer_bonus) }

  include_context 'frozen_time'

  context 'raise errors' do
    subject(:service_call) { described_class.call(bonus: customer_bonus) }

    it 'raise argument error when pass without reason' do
      expect { service_call }.to raise_error(ArgumentError)
    end
  end

  context 'with active customer bonus' do
    let!(:bonus_balance) { create(:balance, :bonus, wallet: wallet) }
    let(:wallet) { customer_bonus.wallet }

    let(:found_entry_request) do
      EntryRequest.confiscation.find_by(origin: wallet)
    end
    let(:comment) do
      "Confiscation of #{bonus_balance.amount} #{wallet.currency} from " \
      "#{wallet.customer} bonus balance."
    end

    before do
      allow(EntryRequests::ConfiscationWorker).to receive(:perform_async)
      described_class.call(bonus: customer_bonus, reason: expiration_reason)
    end

    it 'returns customer bonus with provided expiration reason' do
      expect(customer_bonus.expiration_reason).to eq(expiration_reason)
    end

    it 'removes customer bonus' do
      expect(customer_bonus.deleted_at).not_to be_nil
    end

    it 'creates confiscation entry request' do
      expect(found_entry_request).to have_attributes(
        mode: EntryRequest::INTERNAL,
        amount: -bonus_balance.amount,
        comment: comment,
        customer: wallet.customer,
        currency: wallet.currency
      )
    end

    it 'schedules job for updating wallet' do
      expect(EntryRequests::ConfiscationWorker)
        .to have_received(:perform_async)
        .with(found_entry_request.id)
    end
  end

  context 'with already processed bonus' do
    let(:customer_bonus) do
      create(:customer_bonus, deleted_at: 5.hours.ago,
                              expiration_reason: expiration_reason)
    end

    before do
      described_class
        .call(bonus: customer_bonus, reason: another_expiration_reason)
    end

    it 'does not override expired bonus reason' do
      expect(customer_bonus.expiration_reason).to eq(expiration_reason)
    end

    it 'does not override original expiration date' do
      expect(customer_bonus.deleted_at).to eq(5.hours.ago)
    end
  end
end