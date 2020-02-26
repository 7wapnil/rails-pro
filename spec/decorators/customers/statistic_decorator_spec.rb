# frozen_string_literal: true

describe Customers::StatisticDecorator, type: :decorator do
  subject { object.decorate }

  let(:object) { build(:customer_statistic) }
  let!(:primary_currency) { create(:currency, :primary) }

  describe '#hold_value' do
    it_behaves_like 'decorated amount' do
      let(:amount) { subject.hold_value }
      let(:control_amount) { subject.deposit_value - subject.withdrawal_value }
      let(:precision) { Currency.primary.scale }
      let(:currency_symbol) { '&#8364;' }
    end
  end

  describe '#gross_gaming_revenue' do
    let(:control_category) { Customers::StatisticDecorator::CATEGORIES.sample }
    let(:value) do
      subject.wager(control_category) - subject.payout(control_category)
    end
    let(:decorated_amount) do
      subject.gross_gaming_revenue(control_category, human: true)
    end

    Customers::StatisticDecorator::CATEGORIES.each do |category|
      context(category) do
        let(:control_category) { category }

        it_behaves_like 'decorated amount' do
          let(:amount) { decorated_amount }
          let(:control_amount) { value }
          let(:precision) { Currency.primary.scale }
          let(:currency_symbol) { '&#8364;' }
        end
      end
    end

    context 'with zero amount' do
      let(:object) { build(:customer_statistic, :empty) }

      it 'returns decorated zero' do
        expect(decorated_amount).to eq('0.00 &#8364;')
      end
    end

    context 'with unknown category' do
      let(:control_category) { 'allo' }

      it 'returns decorated zero' do
        expect(decorated_amount).to eq('0.00 &#8364;')
      end
    end

    context 'without passed `human` attribute' do
      let(:decorated_amount) { subject.gross_gaming_revenue(control_category) }

      it 'returns raw amount' do
        expect(decorated_amount).to eq(value)
      end
    end
  end

  describe '#margin' do
    let(:control_category) { Customers::StatisticDecorator::CATEGORIES.sample }
    let(:value) do
      subject.gross_gaming_revenue(control_category) /
        subject.wager(control_category)
    end
    let(:decorated_amount) { subject.margin(control_category) }

    Customers::StatisticDecorator::CATEGORIES.each do |category|
      context(category) do
        let(:control_category) { category }
        let(:expected_amount) do
          helpers.number_to_percentage(
            value * Customers::StatisticDecorator::PERCENTS_MULTIPLIER,
            precision: Currency.primary.scale
          )
        end

        it 'works' do
          expect(decorated_amount).to eq(expected_amount)
        end
      end
    end

    context 'with zero amount' do
      let(:object) { build(:customer_statistic, :empty) }

      it 'returns decorated zero' do
        expect(decorated_amount).to eq('0.00%')
      end
    end
  end

  describe '#wager' do
    context 'total' do
      let(:category) { Customers::StatisticDecorator::TOTAL }
      let(:bet_value) { object.prematch_wager + object.live_sports_wager }
      let(:casino_value) { object.casino_game_wager + object.live_casino_wager }
      let(:value) { bet_value + casino_value }

      it 'returns raw amount' do
        expect(subject.wager(category)).to eq(value)
      end

      it_behaves_like 'decorated amount' do
        let(:amount) { subject.wager(category, human: true) }
        let(:control_amount) { value }
        let(:precision) { Currency.primary.scale }
        let(:currency_symbol) { '&#8364;' }
      end
    end

    context 'total bets' do
      let(:category) { Customers::StatisticDecorator::TOTAL_BETS }
      let(:value) { object.prematch_wager + object.live_sports_wager }

      it 'returns raw amount' do
        expect(subject.wager(category)).to eq(value)
      end

      it_behaves_like 'decorated amount' do
        let(:amount) { subject.wager(category, human: true) }
        let(:control_amount) { value }
        let(:precision) { Currency.primary.scale }
        let(:currency_symbol) { '&#8364;' }
      end
    end

    context 'prematch' do
      let(:category) { Customers::StatisticDecorator::PREMATCH }

      it 'returns raw amount' do
        expect(subject.wager(category)).to eq(object.prematch_wager)
      end

      it_behaves_like 'decorated amount' do
        let(:amount) { subject.wager(category, human: true) }
        let(:control_amount) { object.prematch_wager }
        let(:precision) { Currency.primary.scale }
        let(:currency_symbol) { '&#8364;' }
      end
    end

    context 'live' do
      let(:category) { Customers::StatisticDecorator::LIVE_SPORTS }

      it 'returns raw amount' do
        expect(subject.wager(category)).to eq(object.live_sports_wager)
      end

      it_behaves_like 'decorated amount' do
        let(:amount) { subject.wager(category, human: true) }
        let(:control_amount) { object.live_sports_wager }
        let(:precision) { Currency.primary.scale }
        let(:currency_symbol) { '&#8364;' }
      end
    end

    context 'total casino game' do
      let(:category) { Customers::StatisticDecorator::TOTAL_CASINO }
      let(:value) { object.casino_game_wager + object.live_casino_wager }

      it 'returns raw amount' do
        expect(subject.wager(category)).to eq(value)
      end

      it_behaves_like 'decorated amount' do
        let(:amount) { subject.wager(category, human: true) }
        let(:control_amount) { value }
        let(:precision) { Currency.primary.scale }
        let(:currency_symbol) { '&#8364;' }
      end
    end

    context 'casino game' do
      let(:category) { Customers::StatisticDecorator::CASINO_GAME }

      it 'returns raw amount' do
        expect(subject.wager(category)).to eq(object.casino_game_wager)
      end

      it_behaves_like 'decorated amount' do
        let(:amount) { subject.wager(category, human: true) }
        let(:control_amount) { object.casino_game_wager }
        let(:precision) { Currency.primary.scale }
        let(:currency_symbol) { '&#8364;' }
      end
    end

    context 'casino live game' do
      let(:category) { Customers::StatisticDecorator::LIVE_CASINO }

      it 'returns raw amount' do
        expect(subject.wager(category)).to eq(object.live_casino_wager)
      end

      it_behaves_like 'decorated amount' do
        let(:amount) { subject.wager(category, human: true) }
        let(:control_amount) { object.live_casino_wager }
        let(:precision) { Currency.primary.scale }
        let(:currency_symbol) { '&#8364;' }
      end
    end
  end

  describe '#payout' do
    context 'total' do
      let(:category) { Customers::StatisticDecorator::TOTAL_BETS }
      let(:value) { object.prematch_payout + object.live_sports_payout }

      it 'returns raw amount' do
        expect(subject.payout(category)).to eq(value)
      end

      it_behaves_like 'decorated amount' do
        let(:amount) { subject.payout(category, human: true) }
        let(:control_amount) { value }
        let(:precision) { Currency.primary.scale }
        let(:currency_symbol) { '&#8364;' }
      end
    end

    context 'prematch' do
      let(:category) { Customers::StatisticDecorator::PREMATCH }

      it 'returns raw amount' do
        expect(subject.payout(category)).to eq(object.prematch_payout)
      end

      it_behaves_like 'decorated amount' do
        let(:amount) { subject.payout(category, human: true) }
        let(:control_amount) { object.prematch_payout }
        let(:precision) { Currency.primary.scale }
        let(:currency_symbol) { '&#8364;' }
      end
    end

    context 'live' do
      let(:category) { Customers::StatisticDecorator::LIVE_SPORTS }

      it 'returns raw amount' do
        expect(subject.payout(category)).to eq(object.live_sports_payout)
      end

      it_behaves_like 'decorated amount' do
        let(:amount) { subject.payout(category, human: true) }
        let(:control_amount) { object.live_sports_payout }
        let(:precision) { Currency.primary.scale }
        let(:currency_symbol) { '&#8364;' }
      end
    end
  end

  describe '#average_wager_value' do
    let(:control_category) { Customers::StatisticDecorator::CATEGORIES.sample }
    let(:value) do
      subject.wager(control_category) / subject.count_items(control_category)
    end
    let(:decorated_amount) { subject.average_wager_value(control_category) }

    Customers::StatisticDecorator::CATEGORIES.each do |category|
      context(category) do
        let(:control_category) { category }

        it_behaves_like 'decorated amount' do
          let(:amount) { decorated_amount }
          let(:control_amount) { value }
          let(:precision) { Currency.primary.scale }
          let(:currency_symbol) { '&#8364;' }
        end
      end
    end

    context 'with zero bet count' do
      let(:object) do
        build(
          :customer_statistic,
          prematch_bet_count: 0,
          live_bet_count: 0,
          casino_game_count: 0,
          live_casino_count: 0
        )
      end

      it 'returns decorated zero' do
        expect(decorated_amount).to eq('0.00 &#8364;')
      end
    end

    context 'with unknown category' do
      let(:control_category) { 'allo' }

      it 'returns decorated zero' do
        expect(decorated_amount).to eq('0.00 &#8364;')
      end
    end
  end

  describe '#count_items' do
    context 'total' do
      let(:category) { Customers::StatisticDecorator::TOTAL_BETS }
      let(:value) { object.prematch_bet_count + object.live_bet_count }

      it 'returns correct count' do
        expect(subject.count_items(category)).to eq(value)
      end
    end

    context 'prematch' do
      let(:category) { Customers::StatisticDecorator::PREMATCH }

      it 'returns correct count' do
        expect(subject.count_items(category)).to eq(object.prematch_bet_count)
      end
    end

    context 'live' do
      let(:category) { Customers::StatisticDecorator::LIVE_SPORTS }

      it 'returns correct count' do
        expect(subject.count_items(category)).to eq(object.live_bet_count)
      end
    end
  end

  describe '#total_bonus_awarded' do
    let(:value) { object.total_bonus_awarded }

    it 'returns raw amount' do
      expect(subject.total_bonus_awarded).to eq(value)
    end

    it_behaves_like 'decorated amount' do
      let(:amount) { subject.total_bonus_awarded(human: true) }
      let(:control_amount) { value }
      let(:precision) { Currency.primary.scale }
      let(:currency_symbol) { '&#8364;' }
    end
  end

  describe '#total_bonus_completed' do
    let(:value) { object.total_bonus_completed }

    it 'returns raw amount' do
      expect(subject.total_bonus_completed).to eq(value)
    end

    it_behaves_like 'decorated amount' do
      let(:amount) { subject.total_bonus_completed(human: true) }
      let(:control_amount) { value }
      let(:precision) { Currency.primary.scale }
      let(:currency_symbol) { '&#8364;' }
    end
  end

  describe '#total_pending_bet_sum' do
    let(:value) { object.total_pending_bet_sum }

    it 'returns raw amount' do
      expect(subject.total_pending_bet_sum).to eq(value)
    end

    it_behaves_like 'decorated amount' do
      let(:amount) { subject.total_pending_bet_sum(human: true) }
      let(:control_amount) { value }
      let(:precision) { Currency.primary.scale }
      let(:currency_symbol) { '&#8364;' }
    end
  end

  describe '#deposit_value' do
    let(:value) { object.deposit_value }

    it 'returns raw amount' do
      expect(subject.deposit_value).to eq(value)
    end

    it_behaves_like 'decorated amount' do
      let(:amount) { subject.deposit_value(human: true) }
      let(:control_amount) { value }
      let(:precision) { Currency.primary.scale }
      let(:currency_symbol) { '&#8364;' }
    end
  end

  describe '#withdrawal_value' do
    let(:value) { object.withdrawal_value }

    it 'returns raw amount' do
      expect(subject.withdrawal_value).to eq(value)
    end

    it_behaves_like 'decorated amount' do
      let(:amount) { subject.withdrawal_value(human: true) }
      let(:control_amount) { value }
      let(:precision) { Currency.primary.scale }
      let(:currency_symbol) { '&#8364;' }
    end
  end

  describe '#last_updated_at' do
    let(:label) { Customers::Statistic.human_attribute_name(:last_updated_at) }

    it 'returns raw amount' do
      expect(subject.last_updated_at).to eq(object.last_updated_at)
    end

    context 'when last_updated_at is empty' do
      let(:object) { build(:customer_statistic, :empty) }

      it 'returns n/a' do
        expect(subject.last_updated_at(human: true))
          .to eq("#{label}: #{I18n.t('internal.not_available')}")
      end
    end

    it 'decorates last_updated_at' do
      expect(subject.last_updated_at(human: true))
        .to eq("#{label}: #{I18n.l(object.last_updated_at)}")
    end
  end
end
