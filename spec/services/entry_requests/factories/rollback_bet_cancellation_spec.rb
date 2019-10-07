# frozen_string_literal: true

describe EntryRequests::Factories::RollbackBetCancellation do
  subject { described_class.call(bet: bet) }

  include_context 'base_currency'

  let(:initial_real_money_balance) { wallet.real_money_balance }
  let(:initial_bonus_balance) { wallet.bonus_balance }
  let(:wallet) { create(:wallet, currency: base_currency) }
  let(:customer) { wallet.customer }
  let(:placement_entry_request) do
    create(:entry_request, :system_bet_cancel, :internal,
           amount: bet.amount,
           origin: bet,
           initiator: customer,
           customer: customer,
           currency: bet.currency)
  end
  let!(:placement_entry) do
    create(:entry, :with_balance_entries,
           kind: placement_entry_request.kind,
           origin: placement_entry_request.origin,
           amount: placement_entry_request.amount,
           entry_request: placement_entry_request,
           wallet: wallet)
  end

  context 'lost bet' do
    let(:bet) do
      create(:bet, :cancelled_by_system,
             customer: customer,
             currency: base_currency)
    end

    it 'creates correct entry request' do
      expect(subject.last)
        .to have_attributes(
          bonus_amount: -placement_entry.bonus_amount,
          real_money_amount: -placement_entry.real_money_amount
        )
    end
  end

  context 'won bet' do
    let(:bet) do
      create(:bet, :won, :cancelled_by_system, customer: customer)
    end

    let(:win_entry_request) do
      create(:entry_request, :system_bet_cancel, :internal,
             amount: -bet.amount,
             origin: bet,
             initiator: customer,
             customer: customer,
             currency: bet.currency)
    end

    let!(:winning_entry) do
      create(:entry, :with_balance_entries,
             kind: win_entry_request.kind,
             origin: win_entry_request.origin,
             amount: win_entry_request.amount,
             entry_request: win_entry_request,
             wallet: wallet)
    end

    it 'creates correct amount of entry requests' do
      expect(subject.length).to eq(2)
    end

    it 'creates correct entry requests' do
      expect(subject)
        .to match_array(
          [have_attributes(
            amount: -placement_entry.amount,
            bonus_amount: -placement_entry.bonus_amount,
            real_money_amount: -placement_entry.real_money_amount
          ),
           have_attributes(
             amount: winning_entry.amount,
             bonus_amount: winning_entry.bonus_amount,
             real_money_amount: winning_entry.real_money_amount
           )]
        )
    end
  end
end
