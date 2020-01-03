# frozen_string_literal: true

describe GraphQL, '#recommendedGames' do
  let(:play_item) do
    (category.play_items << create(:casino_game, :with_recommended_games)).first
  end

  let(:category) { create(:category) }
  let(:location) { OpenStruct.new(country_code: 'EST') }
  let(:request) { OpenStruct.new(location: location) }
  let(:context) { { request: request } }
  let(:variables) { {} }
  let(:limit) do
    EveryMatrix::RecommendedGamesResolver::LIMIT_RECOMMENDED_GAMES
  end

  let(:query) do
    %({
        recommendedGames(originalGameId: "#{play_item.id}") {
          id
          name
          description
          url
          shortName
          logoUrl
          backgroundImageUrl
          slug
          type
        }
      })
  end

  let(:result) do
    ArcanebetSchema.execute(query, context: context, variables: variables)
  end

  context 'base query' do
    before do
      category.play_items << play_item.recommended_games
    end

    it 'returns limited list of recommended games' do
      expect(result.dig('data', 'recommendedGames').length)
        .to eq(limit)
    end
  end
end
