# frozen_string_literal: true

describe GraphQL, '#gamesOverview' do
  let(:location) { OpenStruct.new(country_code: 'EST') }
  let(:request) { OpenStruct.new(location: location) }
  let(:context) { { request: request } }
  let(:variables) { {} }
  let!(:customer) { create(:customer) }
  let(:categories) { create_list(:category, 5) }

  let(:query) do
    %({
        gamesOverview() {
          id
          label
          context
          position
          name
          playItems{
            id
            name
            description
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
    before do
      categories.each do |category|
        category.play_items << create_list(:casino_game, 2)
      end
    end

    it 'returns correct number of categories' do
      expect(result.dig('data', 'gamesOverview').length)
        .to be(EveryMatrix::Category.count)
    end

    it 'returns number of play items per category' do
      right_numbers = result.dig('data', 'gamesOverview').map do |category|
        category.dig('playItems').count
      end

      expect(right_numbers.all?(2)).to be(true)
    end
  end

  xcontext 'restricted country' do
    before do
      categories.each do |category|
        category.play_items << create_list(
          :casino_game, 2,
          restricted_territories: [location.country_code]
        )
      end
    end

    it 'return correct number of categories' do
      expect(result.dig('data', 'gamesOverview').length)
        .to be(EveryMatrix::Category.count)
    end

    it 'returns number of play items per category' do
      right_numbers = result.dig('data', 'gamesOverview').map do |category|
        category.dig('playItems').count
      end

      expect(right_numbers.all?(0)).to be(true)
    end
  end
end
