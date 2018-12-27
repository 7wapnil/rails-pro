describe GraphQL, '#titles' do
  let(:context) { {} }
  let(:variables) { {} }
  let(:result) do
    ArcanebetSchema.execute(query,
                            context: context,
                            variables: variables)
  end

  describe 'query' do
    context 'basic query' do
      let(:query) { %({ titles { id name } }) }

      before do
        create_list(:title, 5)
      end

      it 'returns list of titles' do
        expect(result['data']['titles'].count).to eq(5)
      end

      it 'returns ordered by name list of titles' do
        previous_name = nil
        result['data']['titles'].each do |title|
          expect(previous_name < title['name']).to be_truthy if previous_name
          previous_name = title['name']
        end
      end
    end

    context 'with kind' do
      let(:query) do
        %({
            titles (kind: "esports") {
              id
              name
              kind
            }
        })
      end

      before do
        create_list(:title, 5, kind: :sports)
        create_list(:title, 5, kind: :esports)
      end

      it 'returns esports titles list' do
        expect(result['data']['titles'].count).to eq(5)
      end
    end

    context 'with tournaments' do
      let(:query) do
        %({
            titles {
              id
              tournaments {
                id
                name
              }
            }
        })
      end
      let(:title) { create(:title) }

      before do
        create_list(:event_scope, 3, kind: EventScope::TOURNAMENT, title: title)
      end

      it 'returns titles with tournaments' do
        expect(result['data']).not_to be_nil
        expect(result['data']['titles'].count).to eq(1)
        expect(result['data']['titles'][0]['tournaments'].count).to eq(3)
      end
    end

    context 'single title' do
      let(:title) { create(:title) }
      let(:query) do
        %({
            titles (id: #{title.id}) {
              id
            }
        })
      end

      it 'returns single title' do
        expect(result['data']['titles'].count).to eq(1)
        expect(result['data']['titles'][0]['id']).to eq(title.id.to_s)
      end
    end

    context 'with amounts' do
      let(:title) { create(:title) }
      let(:query) do
        %({
            titles {
              id
              eventsAmount
              hasLive
            }
        })
      end

      before do
        create(:event,
               title: title,
               start_at: Time.now,
               end_at: nil,
               traded_live: false)
        create(:event,
               title: title,
               start_at: Time.now,
               end_at: nil,
               traded_live: true)
      end

      it 'returns titles with amounts' do
        expect(result['data']['titles'].count).to eq(1)
        expect(result['data']['titles'][0]['eventsAmount']).to eq(2)
        expect(result['data']['titles'][0]['hasLive']).to eq(true)
      end
    end
  end
end
