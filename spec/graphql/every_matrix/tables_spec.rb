# frozen_string_literal: true

describe GraphQL, '#tables' do
  let(:category) { create(:category) }
  let(:location) { OpenStruct.new(country_code: 'EST') }
  let(:request) { OpenStruct.new(location: location) }
  let(:context) { { request: request } }
  let(:variables) { {} }
  let!(:customer) { create(:customer) }
  let!(:random_amount) { rand(3..6) }

  let(:query) do
    %({
        tables(context: #{category.context}) {
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
    let!(:table_games) { create_list(:casino_table, random_amount, :desktop) }

    before { category.play_items << table_games }

    it 'returns result with all table games' do
      expect(result.dig('data', 'tables', 'collection').length)
        .to eq(table_games.length)
    end
  end

  context 'block restricted country' do
    let!(:table_games) { create_list(:casino_table, random_amount, :desktop) }
    let!(:test_restricted_table) do
      create(:casino_table, restricted_territories: [location.country_code])
    end

    before do
      category.play_items << table_games
      category.play_items << test_restricted_table
    end

    it 'does not return list of excluded games with restricted country' do
      expect(result.dig('data', 'tables', 'collection').length)
        .to eq(table_games.length)
    end
  end
end
