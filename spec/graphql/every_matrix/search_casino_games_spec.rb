# frozen_string_literal: true

describe GraphQL, '#searchCasinoGames' do
  let!(:category) { create(:category) }
  let(:location) { OpenStruct.new(country_code: 'EST') }
  let(:request) { OpenStruct.new(location: location) }
  let(:context) { { request: request } }
  let(:variables) { {} }
  let(:query_name) { '' }

  let(:query) do
    %({
      searchCasinoGames(query: "#{query_name}") {
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

  before { category.play_items << play_item }

  context 'basic query for searching games' do
    let(:play_item) { create(:casino_game, :unique_names) }
    let(:query_name) { play_item.name }

    before { create_list(:casino_game, rand(4..6), :unique_names) }

    it 'returns found game' do
      expect(result.dig('data', 'searchCasinoGames', 'collection', 0, 'id'))
        .to eq(play_item.id)
    end

    context 'with deactivated games' do
      let(:play_item) { create(:casino_game, :unique_names, :deactivated) }

      it 'does not return deactivated games' do
        expect(result.dig('data', 'searchCasinoGames', 'collection').length)
          .to be_zero
      end
    end
  end

  context 'basic query which does not find games' do
    let!(:play_item) { create(:casino_game) }
    let(:query_name) { Faker::Lorem.characters(10) }

    it 'returns empty result' do
      expect(result.dig('data', 'searchCasinoGames', 'collection'))
        .to be_empty
    end
  end
end
