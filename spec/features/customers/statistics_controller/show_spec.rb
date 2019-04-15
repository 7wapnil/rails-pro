# frozen_string_literal: true

describe Customers::StatisticsController, '#show' do
  let(:customer) { create(:customer) }

  before { login_as create(:admin_user), scope: :user }

  it 'creates new Customers::Statistic' do
    expect { visit customer_statistics_path(customer) }
      .to change(Customers::Statistic, :count).by(1)
  end

  it 'refreshes existing Customers::Statistic' do
    customer.statistics.create

    expect { visit customer_statistics_path(customer) }
      .not_to change(Customers::Statistic, :count)
  end

  context 'statistic calculation' do
    let(:attribute) {}
    let(:label) { Customers::Statistic.human_attribute_name(attribute) }

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
    let(:total_wager) { prematch_wager + live_sports_wager }
    let(:total_payout) { prematch_payout + live_sports_payout }
    let(:total_bet_count) { prematch_bet_count + live_bet_count }
    let(:total_gross_gaming_revenue) { total_wager - total_payout }
    let(:prematch_gross_gaming_revenue) { prematch_wager - prematch_payout }
    let(:live_gross_gaming_revenue) { live_sports_wager - live_sports_payout }
    let(:total_margin) { total_gross_gaming_revenue / total_wager }
    let(:prematch_margin) { prematch_gross_gaming_revenue / prematch_wager }
    let(:live_margin) { live_gross_gaming_revenue / live_sports_wager }
    let(:total_pending_bet_sum) do
      [pending_prematch_bets, pending_live_bets].flatten.sum(&:amount)
    end

    let(:stats) do
      {
        deposit_count: successful_deposits.length,
        deposit_value: deposit_value,
        withdrawal_count: successful_withdrawals.length,
        withdrawal_value: withdrawal_value,
        hold_value: deposit_value - withdrawal_value,
        theoretical_bonus_cost: 0.0,
        potential_bonus_cost: 0.0,
        actual_bonus_cost: 0.0,
        total_bonus_value: 0.0,
        prematch_bet_count: prematch_bet_count,
        prematch_wager: prematch_wager,
        prematch_payout: prematch_payout,
        live_bet_count: live_bet_count,
        live_sports_wager: live_sports_wager,
        live_sports_payout: live_sports_payout,
        total_wager: total_wager,
        total_payout: total_payout,
        total_bet_count: total_bet_count,
        total_pending_bet_sum: total_pending_bet_sum,
        total_gross_gaming_revenue: total_gross_gaming_revenue,
        prematch_gross_gaming_revenue: prematch_gross_gaming_revenue,
        live_gross_gaming_revenue: live_gross_gaming_revenue,
        total_margin: total_margin,
        prematch_margin: prematch_margin,
        live_margin: live_margin,
        average_total_bet_value: total_wager / total_bet_count,
        average_prematch_bet_value: prematch_wager / prematch_bet_count,
        average_live_bet_value: live_sports_wager / live_bet_count
      }
    end

    before { visit customer_statistics_path(customer) }

    context 'with integer statistic fields' do
      let(:attribute) do
        %i[deposit_count withdrawal_count
           prematch_bet_count live_bet_count].sample
      end
      let(:value) { stats[attribute] }

      it 'page contains them' do
        expect(page).to have_css("tr.#{attribute}", text: "#{label} #{value}")
      end
    end

    context 'with float statistic fields' do
      let(:attribute) do
        %i[
          deposit_value withdrawal_value prematch_wager prematch_payout
          live_sports_wager live_sports_payout total_pending_bet_sum
          hold_value total_wager total_payout
        ].sample
      end
      let(:value) do
        number_with_precision(stats[attribute], precision: 2)
      end

      it 'page contains them' do
        expect(page).to have_css("tr.#{attribute}", text: "#{label} #{value} €")
      end
    end

    context 'with calculated float statistic fields' do
      let(:attribute) { :total_bet_count }
      let(:value) { stats[attribute] }

      it 'page contains them' do
        expect(page).to have_css("tr.#{attribute}", text: "#{label} #{value}")
      end
    end

    context 'with statistic fields aggregated with respective method' do
      let(:attribute) do
        %i[
          total_gross_gaming_revenue prematch_gross_gaming_revenue
          live_gross_gaming_revenue total_margin prematch_margin
          live_margin average_total_bet_value average_prematch_bet_value
          average_live_bet_value
        ].sample
      end
      let(:value) { number_with_precision(stats[attribute], precision: 2) }

      it 'page contains them' do
        expect(page)
          .to have_css("tr.#{attribute}", text: "#{label} #{value} €")
      end
    end

    context 'with bonus statistic fields' do
      let(:attribute) do
        %i[
          theoretical_bonus_cost potential_bonus_cost
          actual_bonus_cost total_bonus_value
        ].sample
      end
      let(:label) { Customers::Statistic.human_attribute_name(attribute) }

      it 'they are shown as IN DEVELOPMENT' do
        expect(page).to have_css("tr.#{attribute}", text: "#{label} -")
      end
    end
  end
end
