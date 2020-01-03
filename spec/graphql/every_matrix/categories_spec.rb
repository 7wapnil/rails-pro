# frozen_string_literal: true

describe GraphQL, '#categories' do
  let(:location) { OpenStruct.new(country_code: 'EST') }
  let(:request) { OpenStruct.new(location: location) }
  let(:context) { { request: request } }
  let(:variables) { {} }
  let(:kind) { EveryMatrix::Category::CASINO_TYPE }

  let(:query) do
    %({
        categories(kind: #{kind}) {
          id
          label
          context
          position
        }
      })
  end

  let(:result) do
    ArcanebetSchema.execute(query, context: context, variables: variables)
  end

  context 'base query' do
    before do
      create_list(
        :category, 3,
        kind: EveryMatrix::Category::CASINO_TYPE
      )
    end

    it 'returns list with all categories for platform type' do
      expect(result.dig('data', 'categories').length)
        .to eq(EveryMatrix::Category.count)
    end

    context 'with no categories for live casino' do
      let(:kind) { EveryMatrix::Category::TABLE_TYPE }

      it 'returns empty list' do
        expect(result.dig('data', 'categories')).to be_empty
      end
    end
  end
end
