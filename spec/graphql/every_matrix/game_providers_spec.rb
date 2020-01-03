# frozen_string_literal: true

describe GraphQL, '#gameProviders' do
  let(:context) { {} }
  let(:variables) { {} }

  let(:query) do
    %({
        gameProviders() {
          id
          name
          logoUrl
          enabled
          internalImageName
        }
      })
  end

  let(:result) do
    ArcanebetSchema.execute(query, context: context, variables: variables)
  end

  context 'base query' do
    let(:random_amount) { rand(2..5) }

    before do
      create_list(
        :every_matrix_content_provider, random_amount,
        :visible, :as_vendor
      )
    end

    it 'returns list all providers' do
      expect(result.dig('data', 'gameProviders').length)
        .to eql(random_amount)
    end
  end
end
