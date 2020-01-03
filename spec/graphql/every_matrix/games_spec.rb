# frozen_string_literal: true

describe GraphQL, '#games' do
  let(:category) { create(:category) }
  let(:location) { OpenStruct.new(country_code: 'EST') }
  let(:request) { OpenStruct.new(location: location) }
  let(:context) { { request: request } }
  let(:variables) { {} }
  let!(:customer) { create(:customer) }
  let(:rand_number) { rand(3..5) }

  let(:query) do
    %({
        games(context: #{category.context}) {
          pagination {
            count
            items
            page
            pages
            offset
            last
            next
            prev
            from
            to
          }
          collection {
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
        }
      })
  end

  let(:result) do
    ArcanebetSchema.execute(query, context: context, variables: variables)
  end

  context 'base query' do
    let!(:casino_games) { create_list(:casino_game, rand_number, :desktop) }

    before { category.play_items << casino_games }

    it 'returns list of all casino games' do
      expect(result.dig('data', 'games', 'collection').length)
        .to eq(casino_games.length)
    end
  end

  context 'block restricted country' do
    let!(:casino_games) { create_list(:casino_game, rand_number, :desktop) }
    let!(:test_restricted_game) do
      create(:casino_game, restricted_territories: [location.country_code])
    end

    before do
      category.play_items << casino_games
      category.play_items << test_restricted_game
    end

    it 'does not return list of excluded games with restricted country' do
      expect(result.dig('data', 'games', 'collection').length)
        .to eq(casino_games.length)
    end

    it 'returns correct amount of games per category' do
      expect(category.play_items.count).to eq(EveryMatrix::Game.count)
    end
  end
end
