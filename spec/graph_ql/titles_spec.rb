describe GraphQL, '#titles' do
  let(:context) { {} }
  let(:variables) { {} }
  let(:result) do
    ArcanebetSchema.execute(query,
                            context: context,
                            variables: variables)
  end

  context 'basic query' do
    let(:query) { %({ titles { id name } }) }

    before do
      create_list(:title, 5, :with_event)
      create_list(:title, 5)
    end

    it 'returns list of titles with active events' do
      expect(result['data']['titles'].count).to eq(5)
    end

    it 'returns ordered by name list of titles' do
      previous_name = nil
      result['data']['titles'].each do |title|
        expect(previous_name <= title['name']).to be_truthy if previous_name
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
      create_list(:title, 5, :with_event, kind: :sports)
      create_list(:title, 5, :with_event, kind: :esports)
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
    let(:title)           { create(:title, :with_event) }
    let(:control_count)   { rand(1..3) }
    let(:event)           { title.events.first }
    let(:inactive_event)  { create(:event, :inactive) }
    let(:invisible_event) { create(:event, :invisible) }

    before do
      create_list(:event_scope, control_count,
                  events: [event],
                  kind:   EventScope::TOURNAMENT,
                  title:  title)

      create_list(:event_scope, 3,
                  events: [inactive_event],
                  kind:   EventScope::TOURNAMENT,
                  title:  title)

      create(:event_scope, events: [invisible_event],
                           kind:   EventScope::TOURNAMENT,
                           title:  title)
    end

    it 'returns titles with tournaments' do
      expect(result['data']).not_to be_nil
      expect(result['data']['titles'].count).to eq(1)
      expect(result['data']['titles'].first['tournaments'].count)
        .to eq(control_count)
    end

    context 'and multiple events' do
      let(:live_event)     { create(:event, :live,     title: title) }
      let(:upcoming_event) { create(:event, :upcoming, title: title) }

      let(:valid_scopes_count) { control_count + 2 }

      before do
        create(:event_scope, events: [live_event],
                             kind:   EventScope::TOURNAMENT,
                             title:  title)

        create(:event_scope, events: [upcoming_event],
                             kind:   EventScope::TOURNAMENT,
                             title:  title)
      end

      it 'returns titles with tournaments' do
        expect(result['data']).not_to be_nil
        expect(result['data']['titles'].count).to eq(1)
        expect(result['data']['titles'].first['tournaments'].count)
          .to eq(valid_scopes_count)
      end
    end
  end

  context 'single title' do
    let(:title) { create(:title, :with_event) }
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
end
