# frozen_string_literal: true

describe GraphQL, '#validate_combo_bets' do
  let(:query) do
    %(query validateComboBets($odds: [ID]) {
      validateComboBets(odds: $odds) {
        oddId
        valid
        errorMessages
      }
    })
  end

  let(:response) do
    ArcanebetSchema.execute(query, context: {}, variables: variables)
  end
  let(:variables) { { odds: odds.map(&:id) } }
  let(:odd_statuses) { response['data']['validateComboBets'] }

  context 'when uniq attributes' do
    let(:odds) { create_list(:odd, 3) }

    it 'returns all odds with status valid' do
      expect(odd_statuses).to be_all { |odd| odd['valid'] }
    end
  end

  context 'when odd have multiple offences' do
    let(:markets) { create_list(:market, 2) }
    let(:competitor) { create(:competitor) }
    let(:odds) do
      [
        create(:odd, market: markets.first),
        create(:odd, market: markets.first),
        create(:odd, market: markets.last)
      ]
    end
    let(:control_odd) { odds.first }
    let(:control_odd_response) do
      odd_statuses.find { |odd| odd['oddId'] == control_odd.id.to_s }
    end

    before do
      create(:event_competitor, event: markets.first.event,
                                competitor: competitor)
      create(:event_competitor, event: markets.last.event,
                                competitor: competitor)
    end

    it 'returns all odds with status invalid' do
      expect(odd_statuses).to be_all { |odd| !odd['valid'] }
    end

    it 'returns all error message for odd with offence' do
      expect(control_odd_response['errorMessages'])
        .to include(I18n.t('bets.notifications.conflicting_event'),
                    I18n.t('bets.notifications.conflicting_competitor'))
    end
  end
end
