# frozen_string_literal: true

describe GraphqlController, type: :controller do
  subject do
    post :execute, params: body
    JSON.parse(response.body)
  end

  describe '#cacheable' do
    let(:title) { create(:title, name: 'Counter-Strike', kind: Title::ESPORTS) }
    let(:tournament) { create(:event_scope, kind: EventScope::TOURNAMENT) }

    let(:control_count) { rand(1..4) }
    let(:control_events) do
      create_list(:event, control_count, :upcoming, :with_market,
                  title: title, event_scopes: [tournament])
    end

    let(:body) do
      {
        operationName: operationName,
        variables: variables,
        query: query
      }
    end
    let(:operationName) { 'esportEventList' }
    let(:query) do
      %(
        query esportEventList($titleId: ID = null,
                              $context: String = null) {
          esportEvents(context: $context, titleId: $titleId) {
            id
            name
          }
        }
      )
    end
    let(:variables) do
      {
        context: 'upcoming'
      }
    end

    before { control_events }

    context 'cache events' do
      let!(:events) do
        post :execute, params: body
        parsed_response = JSON.parse(response.body)

        parsed_response['data']['esportEvents']
      end

      before do
        create(:event, :upcoming, :with_market,
               title: title, event_scopes: [tournament])
      end

      it 'returns greater number of events' do
        Rails.cache.clear

        expect(subject['data']['esportEvents'].count)
          .to eq(events.count + 1)
      end

      it 'returns the same number of events' do
        expect(subject['data']['esportEvents'].count)
          .to eq(events.count)
      end
    end
  end
end
