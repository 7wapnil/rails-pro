# frozen_string_literal: true

describe EveryMatrix::RecommendedGames::FetchGamesFromApi do
  subject { described_class.call(play_item) }

  let(:operator_key) { 'arcanebet' }
  let(:category) { create(:category) }
  let(:raw_api_url) do
    'http://casino2.stage.everymatrix.com/jsonFeeds/gameRecommendedGames'
  end
  let(:api_url) do
    "#{raw_api_url}/#{operator_key}?ids=#{play_item.id}&platform=PC"
  end
  let(:play_item) do
    (category.play_items << create(:casino_game)).first
  end

  context 'successful fetch' do
    let(:body) { file_fixture('casino/recommended_game_fixture.json').read }

    before do
      allow(ENV).to receive(:[])
        .with('EVERY_MATRIX_RECOMMENDED_GAME_URL')
        .and_return(raw_api_url)
      allow(ENV).to receive(:[])
        .with('EVERY_MATRIX_OPERATOR_KEY')
        .and_return(operator_key)

      JSON.parse(body).dig('games')&.map do |game|
        create(:casino_game, external_id: game['id'])
      end

      stub_request(:get, api_url)
        .to_return(status: 200, body: body, headers: {
                     'content-type': 'application/json'
                   })
    end

    it 'fetches correct amount of play items' do
      expect(subject.length).to be(3)
    end
  end
end
