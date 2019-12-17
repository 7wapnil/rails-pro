# frozen_string_literal: true

describe EntryRequests::Factories::RollbackBetCancellation do
  subject { described_class.call(bet: bet, bet_leg: bet.bet_legs.first) }

  include_context 'base_currency'

  let(:initial_real_money_balance) { wallet.real_money_balance }
  let(:initial_bonus_balance) { wallet.bonus_balance }
  let(:wallet) { create(:wallet, currency: base_currency) }
  let(:customer) { wallet.customer }
  let!(:placement_entry) do
    create(:entry, :with_balance_entries, :bet,
           origin: bet,
           amount: -bet.amount,
           wallet: wallet)
  end
  let!(:cancel_placement_entry) do
    create(:entry, :with_balance_entries, :system_bet_cancel,
           origin: bet,
           amount: placement_entry.amount.abs,
           wallet: wallet)
  end

  let(:odd) { create(:odd, market: create(:market)) }

  context 'lost bet' do
    let(:bet) do
      create(:bet, :cancelled_by_system,
             customer: customer,
             currency: base_currency,
             odd: odd)
    end

    it 'creates correct entry request' do
      expect(subject.last)
        .to have_attributes(
          bonus_amount: placement_entry.bonus_amount,
          real_money_amount: placement_entry.real_money_amount
        )
    end
  end

  context 'won bet' do
    let(:bet) do
      create(:bet, :won, :cancelled_by_system, customer: customer, odd: odd)
    end

    let(:winning_entry) do
      create(:entry, :with_balance_entries, :win,
             origin: bet,
             amount: bet.amount,
             wallet: wallet)
    end

    let!(:cancel_winning_entry) do
      create(:entry, :with_balance_entries, :system_bet_cancel,
             origin: bet,
             amount: -winning_entry.amount,
             wallet: wallet)
    end

    it 'creates correct amount of entry requests' do
      expect(subject.length).to eq(2)
    end

    it 'creates correct entry requests' do
      expect(subject)
        .to match_array(
          [have_attributes(
            amount: -cancel_placement_entry.amount,
            bonus_amount: -cancel_placement_entry.bonus_amount,
            real_money_amount: -cancel_placement_entry.real_money_amount
          ),
           have_attributes(
             amount: cancel_winning_entry.amount.abs,
             bonus_amount: cancel_winning_entry.bonus_amount.abs,
             real_money_amount: cancel_winning_entry.real_money_amount.abs
           )]
        )
    end
  end
end
