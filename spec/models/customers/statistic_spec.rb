# frozen_string_literal: true

describe Customers::Statistic, type: :model do
  subject { build(:customer_statistic) }

  it { is_expected.to belong_to(:customer) }

  it 'table_name is changed' do
    expect(described_class.table_name).to eq('customer_statistics')
  end

  describe '#hold_value' do
    let(:hold_value) do
      subject.deposit_value - subject.withdrawal_value
    end

    it 'works' do
      expect(subject.hold_value).to eq(hold_value)
    end
  end

  describe '#gross_gaming_revenue' do
    let(:control_category) { described_class::CATEGORIES.sample }
    let(:gross_gaming_revenue) do
      subject.wager(control_category) - subject.payout(control_category)
    end

    described_class::CATEGORIES.each do |category|
      context(category) do
        let(:control_category) { category }

        it 'works' do
          expect(subject.gross_gaming_revenue(control_category))
            .to eq(gross_gaming_revenue)
        end
      end
    end
  end

  describe '#margin' do
    let(:control_category) { described_class::CATEGORIES.sample }
    let(:margin) do
      subject.gross_gaming_revenue(control_category) /
        subject.wager(control_category)
    end

    described_class::CATEGORIES.each do |category|
      context(category) do
        let(:control_category) { category }

        it 'works' do
          expect(subject.margin(control_category)).to eq(margin)
        end
      end
    end

    context 'with zero margin' do
      subject do
        build(:customer_statistic, prematch_wager: 0, live_sports_wager: 0)
      end

      it 'works' do
        expect(subject.margin(control_category)).to be_zero
      end
    end
  end

  describe '#wager' do
    context(described_class::TOTAL.to_s) do
      let(:category) { described_class::TOTAL }

      it 'works' do
        expect(subject.wager(category)).to eq(subject.total_wager)
      end
    end

    context(described_class::PREMATCH.to_s) do
      let(:category) { described_class::PREMATCH }

      it 'works' do
        expect(subject.wager(category)).to eq(subject.prematch_wager)
      end
    end

    context(described_class::LIVE.to_s) do
      let(:category) { described_class::LIVE }

      it 'works' do
        expect(subject.wager(category)).to eq(subject.live_sports_wager)
      end
    end
  end

  describe '#total_wager' do
    let(:wager) { subject.prematch_wager + subject.live_sports_wager }

    it 'works' do
      expect(subject.total_wager).to eq(wager)
    end
  end

  describe '#payout' do
    context(described_class::TOTAL.to_s) do
      let(:category) { described_class::TOTAL }

      it 'works' do
        expect(subject.payout(category)).to eq(subject.total_payout)
      end
    end

    context(described_class::PREMATCH.to_s) do
      let(:category) { described_class::PREMATCH }

      it 'works' do
        expect(subject.payout(category)).to eq(subject.prematch_payout)
      end
    end

    context(described_class::LIVE.to_s) do
      let(:category) { described_class::LIVE }

      it 'works' do
        expect(subject.payout(category)).to eq(subject.live_sports_payout)
      end
    end
  end

  describe '#total_payout' do
    let(:payout) { subject.prematch_payout + subject.live_sports_payout }

    it 'works' do
      expect(subject.total_payout).to eq(payout)
    end
  end

  describe '#average_bet_value' do
    let(:control_category) { described_class::CATEGORIES.sample }
    let(:average_bet_value) do
      subject.wager(control_category) / subject.bet_count(control_category)
    end

    described_class::CATEGORIES.each do |category|
      context(category) do
        let(:control_category) { category }

        it 'works' do
          expect(subject.average_bet_value(control_category))
            .to eq(average_bet_value)
        end
      end
    end

    context 'with zero bet count' do
      subject do
        build(:customer_statistic, prematch_bet_count: 0, live_bet_count: 0)
      end

      it 'works' do
        expect(subject.average_bet_value(control_category)).to be_zero
      end
    end
  end

  describe '#bet_count' do
    context(described_class::TOTAL.to_s) do
      let(:category) { described_class::TOTAL }

      it 'works' do
        expect(subject.bet_count(category)).to eq(subject.total_bet_count)
      end
    end

    context(described_class::PREMATCH.to_s) do
      let(:category) { described_class::PREMATCH }

      it 'works' do
        expect(subject.bet_count(category)).to eq(subject.prematch_bet_count)
      end
    end

    context(described_class::LIVE.to_s) do
      let(:category) { described_class::LIVE }

      it 'works' do
        expect(subject.bet_count(category)).to eq(subject.live_bet_count)
      end
    end
  end

  describe '#total_bet_count' do
    let(:bet_count) { subject.prematch_bet_count + subject.live_bet_count }

    it 'works' do
      expect(subject.total_bet_count).to eq(bet_count)
    end
  end

  describe '#total_bonus_value' do
    let(:total_bonus_value) { 0.0 }

    it 'works' do
      expect(subject.total_bonus_value).to eq(total_bonus_value)
    end
  end
end
