# frozen_string_literal: true

describe GraphQL, '#event' do
  let(:context) { {} }
  let(:variables) { {} }

  let(:result) do
    ArcanebetSchema.execute(query, context: context, variables: variables)
  end

  let(:visible) { true }
  let!(:event) { create(:event, visible: visible) }

  let(:query) { %({ event (slug: "#{event.slug}") { id } }) }

  it 'returns valid event' do
    expect(result['data']['event']['id']).to eq(event.id.to_s)
  end

  context 'when event is invisible' do
    let(:visible) { false }

    it 'returns error' do
      expect(result['errors']).not_to be_empty
    end
  end
end
