# frozen_string_literal: true

describe GraphQL, '#tablesOverview' do
  let(:location) { OpenStruct.new(country_code: 'EST') }
  let(:request) { OpenStruct.new(location: location) }
  let(:context) { { request: request } }
  let(:categories) do
    create_list(
      :category, 5,
      kind: EveryMatrix::Category::TABLE_TYPE
    )
  end
  let(:variables) { {} }
  let!(:customer) { create(:customer) }

  let(:query) do
    %({
        tablesOverview() {
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
        category.play_items << create_list(:casino_table, 2)
      end
    end

    it 'return correct number of categories' do
      expect(result.dig('data', 'tablesOverview').length)
        .to be(EveryMatrix::Category.count)
    end

    it 'returns number of play items per category' do
      right_numbers = result.dig('data', 'tablesOverview').map do |category|
        category.dig('playItems').count
      end

      expect(right_numbers.all?(2)).to be(true)
    end
  end

  xcontext 'restricted country' do
    before do
      categories.each do |category|
        category.play_items << create_list(
          :casino_table, 2,
          restricted_territories: [location.country_code]
        )
      end
    end

    it 'return correct number of categories' do
      expect(result.dig('data', 'tablesOverview').length)
        .to be(EveryMatrix::Category.count)
    end

    it 'returns number of play items per category' do
      right_numbers = result.dig('data', 'tablesOverview').map do |category|
        category.dig('playItems').count
      end

      expect(right_numbers.all?(0)).to be(true)
    end
  end
end
