# frozen_string_literal: true

describe GraphQL, '#searchCasinoGames' do
  let(:category) { create(:category) }
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

  context 'basic query for searching games' do
    let(:play_item) { (category.play_items << create(:casino_game)).first }
    let(:query_name) { play_item.name }

    before { create_list(:play_item, rand(4..6)) }

    it 'returns found game' do
      expect(result.dig('data', 'searchCasinoGames', 'collection', 0, 'id'))
        .to eq(play_item.id)
    end
  end

  context 'basic query which does not find games' do
    let(:play_item) { (category.play_items << create(:casino_game)).first }
    let(:query_name) { Faker::Lorem.word }

    it 'returns empty result' do
      expect(result.dig('data', 'searchCasinoGames', 'collection'))
        .to be_empty
    end
  end
end
