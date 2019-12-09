# frozen_string_literal: true

describe BetPlacement::ComboBetsOddsValidationService do
  subject { described_class.call(odds.map(&:id)) }

  context 'when uniq attributes' do
    let(:odds) { create_list(:odd, 3) }

    it 'returns all odds with status valid' do
      expect(subject).to be_all(&:valid?)
    end
  end

  context 'when few odds for the same event' do
    let(:uniq_odds) { create_list(:odd, 2) }
    let(:control_odd) { create(:odd, market: uniq_odds.last.market) }
    let(:odds) { [uniq_odds, control_odd].flatten }

    let(:odd_response) { subject.find { |odd| odd.odd_id == control_odd.id } }

    it 'returns invalid status for odd with offence' do
      expect(odd_response).not_to be_valid
    end

    it 'returns error message for odd with offence' do
      expect(odd_response.error_messages)
        .to include(I18n.t('bets.notifications.conflicting_event'))
    end
  end

  context 'when all odds have the same competitor' do
    let(:markets) { create_list(:market, 2) }
    let(:competitor) { create(:competitor) }
    let(:odds) do
      markets.map do |market|
        create(:odd, market: market)
      end
    end

    before do
      create(:event_competitor, event: markets.first.event,
                                competitor: competitor)
      create(:event_competitor, event: markets.last.event,
                                competitor: competitor)
    end

    it 'returns all odds with status invalid' do
      expect(subject).to be_all { |odd| !odd.valid? }
    end

    it 'returns error message for odd with offence' do
      expect(subject.last.error_messages)
        .to include(I18n.t('bets.notifications.conflicting_competitor'))
    end
  end
end
