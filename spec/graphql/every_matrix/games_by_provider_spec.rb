# frozen_string_literal: true

describe GraphQL, '#gamesByProvider' do
  let(:category) { create(:category) }
  let(:location) { OpenStruct.new(country_code: 'EST') }
  let(:request) { OpenStruct.new(location: location) }
  let(:context) { { request: request } }
  let(:variables) { {} }
  let(:random_amount) { rand(2..5) }
  let(:query_name) { provider.slug }
  let(:provider) do
    create(:every_matrix_content_provider, :visible, :as_vendor)
  end

  let(:query) do
    %({
        gamesByProvider(providerSlug: "#{query_name}") {
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

  context 'base query for casino game' do
    before do
      category.play_items << create_list(:casino_game, random_amount, :desktop)
      provider.play_items << category.play_items
    end

    it 'returns list games for provider' do
      expect(result.dig('data', 'gamesByProvider', 'collection').length)
        .to eq(EveryMatrix::Game.count)
    end
  end

  context 'base query for live casino game' do
    before do
      category.play_items << create_list(:casino_table, random_amount, :desktop)
      provider.play_items << category.play_items
    end

    it 'returns list games for provider' do
      expect(result.dig('data', 'gamesByProvider', 'collection').length)
        .to eq(EveryMatrix::Table.count)
    end
  end

  context 'rejected country' do
    before do
      category.play_items << create_list(
        :casino_game, random_amount,
        restricted_territories: [location.country_code]
      )
      provider.play_items << category.play_items
    end

    it 'returns blank games list' do
      expect(result.dig('data', 'gamesByProvider', 'collection')).to be_empty
    end
  end

  context 'with mobile-only games' do
    before do
      category.play_items << create_list(:casino_game, random_amount, :mobile)
      provider.play_items << category.play_items
    end

    it 'does not return mobile games for desktop request' do
      expect(result.dig('data', 'gamesByProvider', 'collection'))
        .to be_empty
    end
  end

  context 'base query by vendor name' do
    let(:vendor) { create(:every_matrix_vendor, :visible) }
    let(:query_name) { vendor.slug }

    before do
      category.play_items << create_list(:casino_game, random_amount)
      vendor.play_items << category.play_items
    end

    it 'returns list of games by provider' do
      expect(result.dig('data', 'gamesByProvider', 'collection').length)
        .to be(random_amount)
    end
  end
end
