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
        create(:entry, :with_real_money_balance_entry,
               customer: customer),
        *create_list(:entry, rand(1..2), :with_real_money_balance_entry,
                     customer: customer,
                     wallet: customer.wallet),
        *create_list(:entry, rand(1..2), :with_balance_entries,
                     customer: customer,
                     wallet: customer.wallet)
      ]
    end
    let(:successful_deposit_real_money_balance) do
      successful_deposits.map(&:real_money_amount)
    end

    # WITHDRAWALS

    let(:withdrawal) { create(:withdrawal, :succeeded) }
    let!(:withdrawals) do
      [
        create(:entry, :withdraw, :with_real_money_balance_entry,
               customer: customer,
               wallet: customer.wallet,
               origin: build(:withdrawal, :rejected)),
        create(:entry, :withdraw, :with_balance_entries,
               customer: customer,
               wallet: customer.wallet,
               origin: build(:withdrawal))
      ]
    end
    let!(:successful_withdrawals) do
      [
        *create_list(:entry, rand(1..2),
                     :withdraw, :with_real_money_balance_entry,
                     customer: customer,
                     wallet: customer.wallet,
                     origin: withdrawal),
        *create_list(:entry, rand(1..2), :withdraw, :with_balance_entries,
                     customer: customer,
                     wallet: customer.wallet,
                     origin: withdrawal)
      ]
    end
    let(:successful_withdrawal_real_money_balance) do
      successful_withdrawals.map(&:real_money_amount)
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
    let(:awarded_customer_bonus_balance) do
      awarded_customer_bonuses.map(&:entry)
    end

    let!(:bonus_conversion_entries) do
      [
        *create_list(:entry, rand(1..2),
                     :bonus_conversion, :with_real_money_balance_entry,
                     customer: customer,
                     wallet: customer.wallet),
        *create_list(:entry, rand(1..2),
                     :bonus_conversion, :with_balance_entries,
                     customer: customer,
                     wallet: customer.wallet)
      ]
    end
    let(:bonus_conversion_real_money_balance) do
      bonus_conversion_entries.map(&:real_money_amount)
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

    let!(:casino_games) do
      create_list(
        :every_matrix_transaction,
        rand(3..4),
        :wager,
        customer: customer,
        wallet_session: create(
          :wallet_session,
          wallet: customer.wallet
        )
      )
    end

    let!(:won_casino_games) do
      create_list(
        :every_matrix_transaction,
        rand(2..3),
        :result,
        customer: customer,
        wallet_session: create(
          :wallet_session,
          wallet: customer.wallet
        )
      )
    end

    let!(:live_casino_games) do
      create_list(
        :every_matrix_transaction,
        rand(3..4),
        :wager,
        customer: customer,
        wallet_session: create(
          :wallet_session,
          :live_casino,
          wallet: customer.wallet
        )
      )
    end

    let!(:won_live_casino_games) do
      create_list(
        :every_matrix_transaction,
        rand(2..3),
        :result,
        customer: customer,
        wallet_session: create(
          :wallet_session,
          :live_casino,
          wallet: customer.wallet
        )
      )
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
      successful_deposit_real_money_balance.sum.round(2)
    end
    let(:withdrawal_value) do
      successful_withdrawal_real_money_balance.sum.abs.round(2)
    end
    let(:total_bonus_awarded) do
      awarded_customer_bonus_balance.sum(&:bonus_amount).round(2)
    end
    let(:total_bonus_completed) do
      bonus_conversion_real_money_balance.sum.round(2)
    end
    let(:prematch_wager) { settled_prematch_bets.sum(&:amount).round(2) }
    let(:prematch_payout) { won_prematch_bets.sum(&:win_amount).round(2) }
    let(:prematch_bet_count) { settled_prematch_bets.length }
    let(:live_sports_wager) { settled_live_bets.sum(&:amount).round(2) }
    let(:live_sports_payout) { won_live_bets.sum(&:win_amount).round(2) }
    let(:live_bet_count) { settled_live_bets.length }
    let(:casino_game_wager) { casino_games.sum(&:amount) }
    let(:casino_game_payout) { won_casino_games.sum(&:amount) }
    let(:casino_game_count) { casino_games.length }
    let(:live_casino_wager) { live_casino_games.sum(&:amount) }
    let(:live_casino_payout) { won_live_casino_games.sum(&:amount) }
    let(:live_casino_count) { live_casino_games.length }

    let(:total_bet_wager) { prematch_wager + live_sports_wager }
    let(:total_bet_payout) { prematch_payout + live_sports_payout }
    let(:total_casino_wager) { casino_game_wager + live_casino_wager }
    let(:total_casino_payout) { casino_game_payout + live_casino_payout }
    let(:total_wager) { total_bet_wager + total_casino_wager }
    let(:total_payout) { total_bet_payout + total_casino_payout }
    let(:total_bet_count) { prematch_bet_count + live_bet_count }
    let(:total_casino_count) { casino_game_count + live_casino_count }
    let(:total_gross_gaming_revenue) { total_wager - total_payout }
    let(:prematch_gross_gaming_revenue) { prematch_wager - prematch_payout }
    let(:live_bet_gross_gaming_revenue) do
      live_sports_wager - live_sports_payout
    end
    let(:casino_gross_gaming_revenue) { casino_game_wager - casino_game_payout }
    let(:live_casino_gross_gaming_revenue) do
      live_casino_wager - live_casino_payout
    end
    let(:total_margin) { total_gross_gaming_revenue / total_wager }
    let(:prematch_margin) { prematch_gross_gaming_revenue / prematch_wager }
    let(:live_margin) { live_bet_gross_gaming_revenue / live_sports_wager }
    let(:casino_margin) { casino_gross_gaming_revenue / casino_game_wager }
    let(:live_casino_margin) do
      live_casino_gross_gaming_revenue / live_casino_wager
    end
    let(:total_pending_bet_sum) do
      [pending_prematch_bets, pending_live_bets].flatten.sum(&:amount).round(2)
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
        casino_game_wager: casino_game_wager,
        casino_game_payout: casino_game_payout,
        casino_game_count: casino_game_count,
        live_casino_wager: live_casino_wager,
        live_casino_payout: live_casino_payout,
        live_casino_count: live_casino_count,
        total_wager: total_wager,
        total_payout: total_payout,
        total_bet_wager: total_bet_wager,
        total_bet_payout: total_bet_payout,
        total_casino_wager: total_casino_wager,
        total_casino_payout: total_casino_payout,
        total_bet_count: total_bet_count,
        total_casino_count: total_casino_count,
        total_pending_bet_sum: total_pending_bet_sum,
        total_gross_gaming_revenue: total_gross_gaming_revenue,
        prematch_gross_gaming_revenue: prematch_gross_gaming_revenue,
        live_bet_gross_gaming_revenue: live_bet_gross_gaming_revenue,
        casino_gross_gaming_revenue: casino_gross_gaming_revenue,
        live_casino_gross_gaming_revenue: live_casino_gross_gaming_revenue,
        total_margin: total_margin,
        prematch_margin: prematch_margin,
        casino_margin: casino_margin,
        live_casino_margin: live_casino_margin,
        live_margin: live_margin,
        average_total_bet_value: total_bet_wager / total_bet_count,
        average_prematch_bet_value: prematch_wager / prematch_bet_count,
        average_live_bet_value: live_sports_wager / live_bet_count,
        average_wager_total_casino: total_casino_wager / total_casino_count,
        average_wager_casino_game: casino_game_wager / casino_game_count,
        average_wager_live_casino: live_casino_wager / live_casino_count
      }
    end

    before do
      allow(::Exchanger::Converter)
        .to receive(:call).with(any_args) { |amount, *| amount }
      visit customer_statistics_path(customer)
    end

    it 'page contains integer statistic fields' do
      attributes = %i[deposit_count withdrawal_count
                      prematch_bet_count live_bet_count
                      casino_game_count live_casino_count]
      attributes.each do |attribute|
        label = Customers::Statistic.human_attribute_name(attribute)
        value = stats[attribute]

        expect(page)
          .to have_css("tr.#{attribute}", text: "#{label} #{value}")
      end
    end

    it 'page contains aggregated integer statistic fields' do
      attributes = %i[total_bet_count
                      total_casino_count]

      attributes.each do |attribute|
        label = Customers::Statistic.human_attribute_name(attribute)
        value = stats[attribute]

        expect(page)
          .to have_css("tr.#{attribute}", text: "#{label} #{value}")
      end
    end

    it 'page contains percentage statistic fields' do
      attributes = %i[total_margin
                      prematch_margin live_margin
                      casino_margin live_casino_margin]
      attributes.each do |attribute|
        label = Customers::Statistic.human_attribute_name(attribute)
        value = number_with_precision(stats[attribute] * 100, precision: 2)

        expect(page)
          .to have_css("tr.#{attribute}", text: "#{label} #{value}%")
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
        casino_game_wager casino_game_payout
        live_casino_wager live_casino_payout
        total_casino_wager total_casino_payout
        total_gross_gaming_revenue
        prematch_gross_gaming_revenue live_bet_gross_gaming_revenue
        casino_gross_gaming_revenue live_casino_gross_gaming_revenue
        average_total_bet_value average_wager_total_casino
        average_prematch_bet_value average_live_bet_value
        average_wager_casino_game average_wager_live_casino
        total_bet_wager total_bet_payout
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
