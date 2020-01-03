# frozen_string_literal: true

describe EveryMatrix::RecommendedGames::UpdateForGame do
  subject { described_class.call(play_item) }

  let(:play_item) do
    create(:casino_game)
  end
  let(:recommended_games) do
    create_list(:casino_game, 5)
  end

  context 'successful update' do
    before do
      allow(EveryMatrix::RecommendedGames::FetchGamesFromApi)
        .to receive(:call)
        .with(play_item)
        .and_return(recommended_games)

      subject
    end

    it 'updates recommended games' do
      expect(play_item.recommended_games.ids.sort)
        .to eql(recommended_games.pluck(:external_id).sort)
    end

    it 'updates timestamp' do
      expect(play_item.last_updated_recommended_games_at).not_to be_nil
    end
  end
end
