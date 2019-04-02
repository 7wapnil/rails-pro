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
        create(:entry, :win, customer: customer),
        create(:entry, :withdraw, customer: customer),
        create(:entry, :bet, customer: customer),
        create(:entry, :refund, customer: customer)
      ]
    end
    let!(:successful_deposits) do
      create_list(:entry, rand(1..3), customer: customer)
    end

    let(:withdrawal_request) { create(:withdrawal_request, :approved) }
    let!(:withdrawals) do
      [
        create(:entry, :withdraw,
               customer: customer,
               origin: build(:withdrawal_request, :rejected)),
        create(:entry, :withdraw,
               customer: customer,
               origin: build(:withdrawal_request))
      ]
    end
    let!(:successful_withdrawals) do
      create_list(:entry, rand(1..3), :withdraw,
                  customer: customer,
                  origin: withdrawal_request)
    end

    let(:event) { create(:event) }
    let(:market) { create(:market, event: event) }

    let(:external_validation_state) do
      StateMachines::BetStateMachine::SENT_TO_EXTERNAL_VALIDATION
    end

    let(:prematch_attributes) do
      {
        market: market,
        created_at: event.start_at - 1.hour,
        customer: customer
      }
    end
    let!(:prematch_bets) do
      [
        create(:bet, prematch_attributes),
        create(:bet, :cancelled, prematch_attributes),
        create(:bet, :rejected, prematch_attributes),
        create(:bet, :failed, prematch_attributes)
      ]
    end

    let!(:pending_prematch_bets) do
      [
        create(:bet, :sent_to_internal_validation, prematch_attributes),
        create(:bet, :validated_internally, prematch_attributes),
        create(:bet, status: external_validation_state, **prematch_attributes),
        create(:bet, :accepted, prematch_attributes)
      ]
    end
    let(:won_prematch_bets) do
      create_list(:bet, rand(1..3), :settled, :won, prematch_attributes)
    end
    let!(:settled_prematch_bets) do
      [
        create_list(:bet, rand(1..3), :settled, prematch_attributes),
        won_prematch_bets
      ].flatten
    end

    let(:live_attributes) { { market: market, customer: customer } }
    let!(:live_bets) do
      [
        create(:bet, live_attributes),
        create(:bet, :cancelled, live_attributes),
        create(:bet, :rejected, live_attributes),
        create(:bet, :failed, live_attributes)
      ]
    end
    let!(:pending_live_bets) do
      [
        create(:bet, :sent_to_internal_validation, live_attributes),
        create(:bet, :validated_internally, live_attributes),
        create(:bet, status: external_validation_state, **live_attributes),
        create(:bet, :accepted, live_attributes)
      ]
    end
    let(:won_live_bets) do
      create_list(:bet, rand(1..3), :settled, :won, live_attributes)
    end
    let!(:settled_live_bets) do
      [
        create_list(:bet, rand(1..3), :settled, live_attributes),
        won_live_bets
      ].flatten
    end

    let(:deposit_value) { successful_deposits.sum(&:amount) }
    let(:withdrawal_value) { successful_withdrawals.sum(&:amount).abs }
    let(:prematch_wager) { settled_prematch_bets.sum(&:amount) }
    let(:prematch_payout) { won_prematch_bets.sum(&:amount) }
    let(:prematch_bet_count) { settled_prematch_bets.length }
    let(:live_sports_wager) { settled_live_bets.sum(&:amount) }
    let(:live_sports_payout) { won_live_bets.sum(&:amount) }
    let(:live_bet_count) { settled_live_bets.length }
    let(:total_pending_bet_sum) do
      [pending_prematch_bets, pending_live_bets].flatten.sum(&:amount)
    end

    let(:current_time) { Time.zone.now }

    include_context 'frozen_time' do
      let(:frozen_time) { current_time }
    end

    it 'returns stats with expected numbers' do
      expect(subject).to have_attributes(
        deposit_count: successful_deposits.length,
        deposit_value: deposit_value,
        withdrawal_count: successful_withdrawals.length,
        withdrawal_value: withdrawal_value,
        theoretical_bonus_cost: 0.0,
        potential_bonus_cost: 0.0,
        actual_bonus_cost: 0.0,
        prematch_bet_count: prematch_bet_count,
        prematch_wager: prematch_wager,
        prematch_payout: prematch_payout,
        live_bet_count: live_bet_count,
        live_sports_wager: live_sports_wager,
        live_sports_payout: live_sports_payout,
        total_pending_bet_sum: total_pending_bet_sum,
        updated_at: current_time
      )
    end

    context 'for pre-calculated stats' do
      let!(:stats) do
        create(:customer_statistic, customer: customer, updated_at: 1.month.ago)
      end
      let(:expected_withdrawal_count) do
        successful_withdrawals.length + stats.withdrawal_count
      end
      let(:expected_total_pending_bet_sum) do
        total_pending_bet_sum + stats.total_pending_bet_sum
      end

      it 'returns stats with expected numbers' do
        expect(subject).to have_attributes(
          deposit_count: successful_deposits.length + stats.deposit_count,
          deposit_value: deposit_value + stats.deposit_value,
          withdrawal_count: expected_withdrawal_count,
          withdrawal_value: withdrawal_value + stats.withdrawal_value,
          theoretical_bonus_cost: stats.theoretical_bonus_cost,
          potential_bonus_cost: stats.potential_bonus_cost,
          actual_bonus_cost: stats.actual_bonus_cost,
          prematch_bet_count: prematch_bet_count + stats.prematch_bet_count,
          prematch_wager: prematch_wager + stats.prematch_wager,
          prematch_payout: prematch_payout + stats.prematch_payout,
          live_bet_count: live_bet_count + stats.live_bet_count,
          live_sports_wager: live_sports_wager + stats.live_sports_wager,
          live_sports_payout: live_sports_payout + stats.live_sports_payout,
          total_pending_bet_sum: expected_total_pending_bet_sum,
          updated_at: current_time
        )
      end
    end
  end
end
