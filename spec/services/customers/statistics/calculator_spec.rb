# frozen_string_literal: true

describe Customers::Statistics::Calculator do
  subject { described_class.call(customer: customer) }

  let(:customer) { create(:customer) }

  it 'creates new Customers::Statistic' do
    expect { subject }.to change(Customers::Statistic, :count).by(1)
  end

  it 'refreshes existing Customers::Statistic' do
    customer.statistics.create

    expect { subject }.not_to change(Customers::Statistic, :count)
  end

  context 'statistic calculation' do
    let!(:entries) do
      [
        create(:entry, :win,
               customer: customer),
        create(:entry, :withdraw,
               customer: customer,
               wallet: customer.wallets.first),
        create(:entry, :bet,
               customer: customer,
               wallet: customer.wallets.first),
        create(:entry, :refund,
               customer: customer,
               wallet: customer.wallets.first)
      ]
    end

    # DEPOSITS

    let!(:successful_deposits) do
      [
        *create_list(:entry, rand(1..2), :with_real_money_balance_entry,
                     customer: customer,
                     wallet: customer.wallets.first),
        *create_list(:entry, rand(1..2), :with_balance_entries,
                     customer: customer,
                     wallet: customer.wallets.first)
      ]
    end
    let(:successful_deposit_entries) do
      successful_deposits
    end

    # WITHDRAWALS

    let(:withdrawal) { create(:withdrawal, :succeeded) }
    let!(:withdrawals) do
      [
        create(:entry, :withdraw, :with_real_money_balance_entry,
               customer: customer,
               wallet: customer.wallets.first,
               origin: build(:withdrawal, :rejected)),
        create(:entry, :withdraw, :with_balance_entries,
               customer: customer,
               wallet: customer.wallets.first,
               origin: build(:withdrawal))
      ]
    end
    let!(:successful_withdrawals) do
      [
        *create_list(:entry, rand(1..2),
                     :withdraw, :with_real_money_balance_entry,
                     customer: customer,
                     wallet: customer.wallets.first,
                     origin: withdrawal),
        *create_list(:entry, rand(1..2), :withdraw, :with_balance_entries,
                     customer: customer,
                     wallet: customer.wallets.first,
                     origin: withdrawal)
      ]
    end
    let(:successful_withdrawal_entries) do
      successful_withdrawals
    end

    # BONUSES

    let!(:not_included_customer_bonuses) do
      CustomerBonus
        .statuses
        .keys
        .map(&:to_sym)
        .map { |status| create(:customer_bonus, status, customer: customer) }
    end
    let!(:awarded_customer_bonuses) do
      create_list(:customer_bonus, rand(1..3), :active, :with_entry,
                  customer: customer)
    end
    let(:awarded_customer_bonus_entries) do
      awarded_customer_bonuses.map(&:activation_entry)
    end

    let!(:bonus_conversion_entries) do
      [

        *create_list(:entry, rand(1..2),
                     :bonus_conversion, :with_real_money_balance_entry,
                     customer: customer,
                     wallet: customer.wallets.first),
        *create_list(:entry, rand(1..2),
                     :bonus_conversion, :with_balance_entries,
                     customer: customer,
                     wallet: customer.wallets.first)
      ]
    end
    let(:bonus_conversion_real_money_entries) do
      bonus_conversion_entries
    end

    # BETS

    let(:event) { create(:event) }
    let(:market) { create(:market, event: event) }
    let(:odd) { create(:odd, market: market) }

    let(:external_validation_state) do
      StateMachines::BetStateMachine::SENT_TO_EXTERNAL_VALIDATION
    end

    let(:prematch_attributes) do
      {
        odd: odd,
        created_at: event.start_at - 1.hour,
        customer: customer
      }
    end
    let!(:prematch_bets) do
      [
        create(:bet, :cancelled, :with_bet_leg, prematch_attributes),
        create(:bet, :rejected, :with_bet_leg, prematch_attributes),
        create(:bet, :failed, :with_bet_leg, prematch_attributes)
      ]
    end

    let!(:pending_prematch_bets) do
      [
        create(:bet, :with_bet_leg, prematch_attributes),
        create(:bet, :with_bet_leg, :sent_to_internal_validation,
               prematch_attributes),
        create(:bet, :with_bet_leg, :validated_internally,
               prematch_attributes),
        create(:bet, :with_bet_leg, status: external_validation_state,
                                    **prematch_attributes),
        create(:bet, :with_bet_leg, :accepted, prematch_attributes)
      ]
    end
    let(:won_prematch_bets) do
      [
        create_list(:bet, rand(1..3), :settled, :won, :with_bet_leg,
                    prematch_attributes),
        create(:bet, :won, :manually_settled, :with_bet_leg,
               prematch_attributes)
      ].flatten
    end
    let!(:settled_prematch_bets) do
      [
        create_list(:bet, rand(1..3), :settled, :with_bet_leg,
                    prematch_attributes),
        won_prematch_bets
      ].flatten
    end

    let(:live_attributes) { { odd: odd, customer: customer } }
    let!(:live_bets) do
      [
        create(:bet, :cancelled, :with_bet_leg, live_attributes),
        create(:bet, :rejected, :with_bet_leg, live_attributes),
        create(:bet, :failed, :with_bet_leg, live_attributes)
      ]
    end
    let!(:pending_live_bets) do
      [
        create(:bet, :with_bet_leg, live_attributes),
        create(:bet, :sent_to_internal_validation, :with_bet_leg,
               live_attributes),
        create(:bet, :validated_internally, :with_bet_leg, live_attributes),
        create(:bet, :with_bet_leg, status: external_validation_state,
                                    **live_attributes),
        create(:bet, :accepted, :with_bet_leg, live_attributes)
      ]
    end
    let(:won_live_bets) do
      create_list(:bet, rand(1..3), :settled, :won, :with_bet_leg,
                  live_attributes)
    end
    let!(:settled_live_bets) do
      [
        create_list(:bet, rand(1..3), :settled, :with_bet_leg,
                    live_attributes),
        won_live_bets
      ].flatten
    end

    # CALCULATED VALUES

    let(:deposit_value) do
      successful_deposit_entries.sum(&:real_money_amount)
    end
    let(:withdrawal_value) do
      successful_withdrawal_entries.sum(&:real_money_amount).abs
    end
    let(:total_bonus_awarded) do
      awarded_customer_bonus_entries.sum(&:bonus_amount)
    end
    let(:total_bonus_completed) do
      bonus_conversion_real_money_entries.sum(&:real_money_amount)
    end
    let(:prematch_wager) { settled_prematch_bets.sum(&:amount) }
    let(:prematch_payout) { won_prematch_bets.sum(&:win_amount).round(2) }
    let(:prematch_bet_count) { settled_prematch_bets.length }
    let(:live_sports_wager) { settled_live_bets.sum(&:amount) }
    let(:live_sports_payout) { won_live_bets.sum(&:win_amount).round(2) }
    let(:live_bet_count) { settled_live_bets.length }
    let(:total_pending_bet_sum) do
      [pending_prematch_bets, pending_live_bets].flatten.sum(&:amount)
    end

    let(:current_time) { Time.zone.now }

    include_context 'frozen_time' do
      let(:frozen_time) { current_time }
    end

    before do
      allow(::Exchanger::Converter)
        .to receive(:call).with(any_args) { |amount, *| amount }
    end

    it 'returns stats with expected numbers' do
      expect(subject).to have_attributes(
        deposit_count: successful_deposits.length,
        deposit_value: deposit_value,
        withdrawal_count: successful_withdrawals.length,
        withdrawal_value: withdrawal_value,
        total_bonus_awarded: total_bonus_awarded,
        total_bonus_completed: total_bonus_completed,
        prematch_bet_count: prematch_bet_count,
        prematch_wager: prematch_wager,
        prematch_payout: prematch_payout,
        live_bet_count: live_bet_count,
        live_sports_wager: live_sports_wager,
        live_sports_payout: live_sports_payout,
        total_pending_bet_sum: total_pending_bet_sum,
        updated_at: current_time,
        last_updated_at: nil
      )
    end

    context 'for pre-calculated stats' do
      let!(:stats) do
        create(:customer_statistic, customer: customer, updated_at: 1.month.ago)
      end
      let(:expected_withdrawal_count) do
        successful_withdrawals.length + stats.withdrawal_count
      end
      let(:expected_total_bonus_completed) do
        stats.total_bonus_completed + total_bonus_completed
      end

      it 'returns stats with expected numbers' do
        expect(subject).to have_attributes(
          deposit_count: successful_deposits.length + stats.deposit_count,
          deposit_value: deposit_value + stats.deposit_value,
          withdrawal_count: expected_withdrawal_count,
          withdrawal_value: withdrawal_value + stats.withdrawal_value,
          total_bonus_awarded: total_bonus_awarded,
          total_bonus_completed: expected_total_bonus_completed,
          prematch_bet_count: prematch_bet_count + stats.prematch_bet_count,
          prematch_wager: prematch_wager + stats.prematch_wager,
          prematch_payout: prematch_payout + stats.prematch_payout,
          live_bet_count: live_bet_count + stats.live_bet_count,
          live_sports_wager: live_sports_wager + stats.live_sports_wager,
          live_sports_payout: live_sports_payout + stats.live_sports_payout,
          total_pending_bet_sum: total_pending_bet_sum,
          updated_at: current_time
        )
      end

      it 'returns last_updated_at from previous updated_at' do
        expect(subject.last_updated_at.to_s).to eq(stats.updated_at.to_s)
      end
    end
  end
end
