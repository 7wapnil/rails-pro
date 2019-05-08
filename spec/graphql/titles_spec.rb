describe GraphQL, '#titles' do
  let(:context) { {} }
  let(:variables) { {} }
  let(:result) do
    ArcanebetSchema.execute(query,
                            context: context,
                            variables: variables)
  end

  let(:result_titles) { result['data']['titles'] }
  let(:result_title_ids) { result_titles.map { |title| title['id'].to_i } }

  let(:control_count) { rand(1..4) }

  context 'basic query' do
    let(:query) { %({ titles { id name } }) }

    let!(:control_titles) { create_list(:title, control_count, :with_event) }

    before { create_list(:title, 5) }

    it 'returns ordered by name list of titles with active events' do
      expect(result_title_ids).to match_array(control_titles.map(&:id))
    end
  end

  context 'with kind' do
    let(:query) do
      %({
          titles (kind: "esports") {
            id
            name
            kind
            show_category_in_navigation
          }
      })
    end

    let!(:control_titles) do
      create_list(:title, control_count, :with_event, kind: Title::ESPORTS)
    end

    let(:control_title_ids) { control_titles.sort_by(&:position).map(&:id) }

    before { create_list(:title, 5, :with_event, kind: Title::SPORTS) }

    it 'returns esports titles list' do
      expect(result_title_ids).to eq(control_title_ids)
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

    let(:title) { create(:title, :with_event) }
    let(:event) { title.events.first }
    let(:inactive_event) { create(:event, :inactive) }
    let(:invisible_event) { create(:event, :invisible) }

    let(:result_tournament_ids) do
      result_titles.first['tournaments'].map { |title| title['id'].to_i }
    end

    let!(:control_tournaments) do
      create_list(:event_scope, control_count,
                  events: [event],
                  kind: EventScope::TOURNAMENT,
                  title: title)
    end

    before do
      create_list(:event_scope, 3,
                  events: [inactive_event],
                  kind: EventScope::TOURNAMENT,
                  title: title)

      create(:event_scope, events: [invisible_event],
                           kind: EventScope::TOURNAMENT,
                           title: title)
    end

    it 'returns single title' do
      expect(result_titles.length).to eq(1)
      expect(result_titles.first['id']).to eq(title.id.to_s)
    end

    it 'returns titles with tournaments' do
      expect(result_tournament_ids)
        .to match_array(control_tournaments.map(&:id))
    end

    context 'and multiple events' do
      let(:live_event) { create(:event, :live, title: title) }
      let(:upcoming_event) { create(:event, :upcoming, title: title) }

      let!(:tournament_with_live_event) do
        create(:event_scope,
               events: [live_event],
               kind: EventScope::TOURNAMENT,
               title: title)
      end

      let!(:tournament_with_upcoming_event) do
        create(:event_scope,
               events: [upcoming_event],
               kind: EventScope::TOURNAMENT,
               title: title)
      end

      let(:valid_tournaments) do
        [*control_tournaments,
         tournament_with_live_event,
         tournament_with_upcoming_event]
      end

      it 'returns single title' do
        expect(result_titles.length).to eq(1)
        expect(result_titles.first['id']).to eq(title.id.to_s)
      end

      it 'returns titles with tournaments' do
        expect(result_tournament_ids)
          .to match_array(valid_tournaments.map(&:id))
      end
    end
  end

  context 'with event scopes' do
    let(:query) do
      %({
          titles {
            event_scopes {
              id
              name
              kind
            }
          }
      })
    end

    let(:title) { create(:title, :with_event) }
    let(:control_count) { rand(1..3) }
    let(:event) { title.events.first }

    let(:inactive_event) { create(:event, :inactive, title: title) }
    let(:invisible_event) { create(:event, :invisible, title: title) }

    let(:result_event_scope_ids) do
      result_titles.first['event_scopes'].map { |scope| scope['id'].to_i }
    end

    let!(:control_event_scopes) do
      create_list(:event_scope, control_count,
                  events: [event],
                  title: title)
    end

    before do
      create(:event_scope, events: [inactive_event], title: title)
      create(:event_scope, events: [invisible_event], title: title)
    end

    it 'returns event_scopes attributes' do
      expect(result_event_scope_ids)
        .to match_array(control_event_scopes.map(&:id))
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
      expect(result_titles.length).to eq(1)
      expect(result_titles.first['id']).to eq(title.id.to_s)
    end
  end

  context 'with upcoming_for_time context' do
    let(:query) do
      %({
          titles (context: "upcoming_for_time") {
            id
          }
      })
    end

    let!(:upcoming_for_time_event) do
      create(:event,
             start_at:
               (Event::UPCOMING_DURATION - 1)
                 .hours.from_now,
             end_at: nil)
    end

    let!(:event_in_future) do
      create(:event,
             start_at:
               (Event::UPCOMING_DURATION + 1)
                 .hours.from_now,
             end_at: nil)
    end

    it 'returns upcoming for time titles list' do
      expect(result_title_ids).to eq([upcoming_for_time_event.title.id])
    end
  end
end
