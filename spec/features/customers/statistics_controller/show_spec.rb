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

    # DEPOSITS

    let!(:successful_deposits) do
      [
        *create_list(:entry, rand(1..2), :with_real_money_balance_entry,
                     customer: customer),
        *create_list(:entry, rand(1..2), :with_balance_entries,
                     customer: customer)
      ]
    end
    let(:successful_deposit_real_money_balance_entries) do
      successful_deposits.map(&:real_money_balance_entry)
    end

    # WITHDRAWALS

    let(:withdrawal) { create(:withdrawal, :approved) }
    let!(:withdrawals) do
      [
        create(:entry, :withdraw, :with_real_money_balance_entry,
               customer: customer,
               origin: build(:withdrawal, :rejected)),
        create(:entry, :withdraw, :with_balance_entries,
               customer: customer,
               origin: build(:withdrawal))
      ]
    end
    let!(:successful_withdrawals) do
      [
        *create_list(:entry, rand(1..2),
                     :withdraw, :with_real_money_balance_entry,
                     customer: customer,
                     origin: withdrawal),
        *create_list(:entry, rand(1..2), :withdraw, :with_balance_entries,
                     customer: customer,
                     origin: withdrawal)
      ]
    end
    let(:successful_withdrawal_real_money_balance_entries) do
      successful_withdrawals.map(&:real_money_balance_entry)
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
      create_list(:customer_bonus, rand(1..3), :active, :with_balance_entry,
                  customer: customer)
    end
    let(:awarded_customer_bonus_balance_entries) do
      awarded_customer_bonuses.map(&:balance_entry)
    end

    let!(:bonus_conversion_entries) do
      [
        *create_list(:entry, rand(1..2),
                     :bonus_conversion, :with_real_money_balance_entry,
                     customer: customer),
        *create_list(:entry, rand(1..2),
                     :bonus_conversion, :with_balance_entries,
                     customer: customer)
      ]
    end
    let(:bonus_conversion_real_money_balance_entries) do
      bonus_conversion_entries.map(&:real_money_balance_entry)
    end

    # BETS

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
        create(:bet, :cancelled, prematch_attributes),
        create(:bet, :rejected, prematch_attributes),
        create(:bet, :failed, prematch_attributes)
      ]
    end
    let!(:pending_prematch_bets) do
      [
        create(:bet, prematch_attributes),
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
        create(:bet, :cancelled, live_attributes),
        create(:bet, :rejected, live_attributes),
        create(:bet, :failed, live_attributes)
      ]
    end
    let!(:pending_live_bets) do
      [
        create(:bet, live_attributes),
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

    # CALCULATED VALUES

    let(:deposit_value) do
      successful_deposit_real_money_balance_entries.sum(&:amount)
    end
    let(:withdrawal_value) do
      successful_withdrawal_real_money_balance_entries.sum(&:amount).abs
    end
    let(:total_bonus_awarded) do
      awarded_customer_bonus_balance_entries.sum(&:amount)
    end
    let(:total_bonus_completed) do
      bonus_conversion_real_money_balance_entries.sum(&:amount)
    end
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
        total_bonus_awarded: total_bonus_awarded,
        total_bonus_completed: total_bonus_completed,
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

    it 'page contains integer statistic fields' do
      attributes = %i[deposit_count withdrawal_count
                      prematch_bet_count live_bet_count]
      attributes.each do |attribute|
        label = Customers::Statistic.human_attribute_name(attribute)
        value = stats[attribute]

        expect(page)
          .to have_css("tr.#{attribute}", text: "#{label} #{value}")
      end
    end

    it 'page contains aggregated integer statistic fields' do
      attributes = %i[total_bet_count]
      attributes.each do |attribute|
        label = Customers::Statistic.human_attribute_name(attribute)
        value = stats[attribute]

        expect(page)
          .to have_css("tr.#{attribute}", text: "#{label} #{value}")
      end
    end

    it 'page contains float statistic fields' do
      attributes = %i[
        deposit_value withdrawal_value prematch_wager prematch_payout
        live_sports_wager live_sports_payout total_pending_bet_sum
        hold_value total_bonus_awarded total_bonus_completed
      ]
      attributes.each do |attribute|
        label = Customers::Statistic.human_attribute_name(attribute)
        value = number_with_precision(stats[attribute], precision: 2)

        expect(page)
          .to have_css("tr.#{attribute}", text: "#{label} #{value} €")
      end
    end

    it 'page contains aggregated float statistic fields' do
      attributes = %i[
        total_gross_gaming_revenue prematch_gross_gaming_revenue
        live_gross_gaming_revenue total_margin prematch_margin
        live_margin average_total_bet_value average_prematch_bet_value
        average_live_bet_value total_wager total_payout
      ]
      attributes.each do |attribute|
        label = Customers::Statistic.human_attribute_name(attribute)
        value = number_with_precision(stats[attribute], precision: 2)

        expect(page)
          .to have_css("tr.#{attribute}", text: "#{label} #{value} €")
      end
    end
  end

  context 'with last_updated_at' do
    let(:label) do
      Customers::Statistic.human_attribute_name(:last_updated_at)
    end
    let!(:stats) { create(:customer_statistic, customer: customer) }

    before { visit customer_statistics_path(customer) }

    it 'is shown on page' do
      expect(page).to have_css(
        'small.last_updated_at',
        text: "#{label}: #{I18n.l(stats.updated_at)}"
      )
    end
  end

  context 'without last_updated_at' do
    let(:label) do
      Customers::Statistic.human_attribute_name(:last_updated_at)
    end

    before { visit customer_statistics_path(customer) }

    it 'when stats has not been generated yet is shown on page' do
      expect(page).to have_css('small.last_updated_at', text: "#{label}: N/A")
    end
  end
end
