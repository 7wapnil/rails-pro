describe Event do
  it { should belong_to(:title) }
  it { should have_many(:markets) }
  it { should have_many(:scoped_events) }
  it { should have_many(:event_scopes).through(:scoped_events) }

  it { should validate_presence_of(:name) }

  it { should delegate_method(:name).to(:title).with_prefix }

  it 'returns details adapter' do
    expect(subject.details).to be_a(EventDetails::Base)
  end

  describe '.in_play' do
    it 'includes started and not finished events that are traded live' do
      event = create(:event,
                     start_at: 5.minutes.ago,
                     end_at: nil,
                     traded_live: true)

      expect(Event.in_play).to include(event)
    end

    it 'doesn\'t include not started events' do
      event = create(:event,
                     start_at: 5.minutes.from_now,
                     end_at: nil,
                     traded_live: true)

      expect(Event.in_play).not_to include(event)
    end

    it 'doesn\'t include finished events' do
      event = create(:event,
                     start_at: 1.hour.ago,
                     end_at: 5.minutes.ago,
                     traded_live: true)

      expect(Event.in_play).not_to include(event)
    end

    it 'doesn\'t include events that are not traded live' do
      event = create(:event,
                     start_at: 5.minutes.ago,
                     end_at: nil,
                     traded_live: false)

      expect(Event.in_play).not_to include(event)
    end

    it 'doesn\'t include events that started longer than 4 hours ago' do
      event = create(:event,
                     start_at: 245.minutes.ago,
                     end_at: nil,
                     traded_live: true)

      expect(Event.in_play).not_to include(event)
    end
  end

  describe '.upcoming' do
    it 'includes not started events' do
      event = create(:event, start_at: 5.minutes.from_now, end_at: nil)
      expect(Event.upcoming).to include(event)
    end

    it 'doesn\'t include started events' do
      event = create(:event, start_at: 5.minutes.ago)
      expect(Event.upcoming).not_to include(event)
    end

    it 'doesn\'t include ended events' do
      event = create(:event, start_at: 1.hour.ago, end_at: 5.minutes.ago)
      expect(Event.upcoming).not_to include(event)
    end

    it 'doesn\'t include events with :end_at in future' do
      event = create(:event, start_at: 1.hour.ago, end_at: 5.minutes.from_now)
      expect(Event.upcoming).not_to include(event)
    end
  end

  describe '.unpopular_live' do
    it 'includes finished live events' do
      event = create(:event, traded_live: true, end_at: 5.minutes.ago)
      expect(Event.unpopular_live).to include(event)
    end

    it 'doesn\'t include not finished live events' do
      event = create(:event, traded_live: true, start_at: 5.minutes.ago, end_at: nil)
      expect(Event.unpopular_live).not_to include(event)
    end

    it 'doesn\'t include pre live events' do
      event = create(:event, end_at: 5.minutes.ago)
      expect(Event.unpopular_live).not_to include(event)
    end

    it 'doesn\'t include live events with :end_at in future' do
      event = create(:event, traded_live: true, end_at: 5.minutes.from_now)
      expect(Event.unpopular_live).not_to include(event)
    end
  end

  describe '.unpopular_pre_live' do
    it 'includes finished pre live events' do
      event = create(:event, start_at: 5.minutes.ago)
      expect(Event.unpopular_pre_live).to include(event)
    end

    it 'doesn\'t include not started pre live events' do
      event = create(:event, start_at: 5.minutes.from_now)
      expect(Event.unpopular_pre_live).not_to include(event)
    end

    it 'doesn\'t include live events' do
      event = create(:event, traded_live: true, start_at: 5.minutes.ago)
      expect(Event.unpopular_pre_live).not_to include(event)
    end

    it 'doesn\'t include pre live events with :start_at in future' do
      event = create(:event, start_at: 5.minutes.from_now)
      expect(Event.unpopular_pre_live).not_to include(event)
    end
  end

  describe '#in_play?' do
    it 'is true when started, not finished and is traded live' do
      event = create(:event,
                     start_at: 5.minutes.ago,
                     end_at: nil,
                     traded_live: true)

      expect(event.in_play?).to be true
    end

    it 'is false when not started' do
      event = create(:event,
                     start_at: 5.minutes.from_now,
                     end_at: nil,
                     traded_live: true)

      expect(event.in_play?).not_to be true
    end

    it 'is false when finished' do
      event = create(:event,
                     start_at: 1.hour.ago,
                     end_at: 5.minutes.ago,
                     traded_live: true)

      expect(event.in_play?).not_to be true
    end

    it 'is false when not traded live' do
      event = create(:event,
                     start_at: 5.minutes.ago,
                     end_at: nil,
                     traded_live: false)

      expect(event.in_play?).not_to be true
    end
  end

  describe '#update_from!' do
    let(:updatable_attributes) do
      {
        name: 'Foo vs Bar',
        description: 'Super Mega match',
        start_at: 1.day.from_now
      }
    end

    let(:event) { create(:event) }
    let(:other) { build(:event, updatable_attributes) }

    it 'fails with TypeError when not an Event argument is passed' do
      expect { event.update_from!(:foo) }
        .to raise_error(TypeError, 'Passed \'other\' argument is not an Event')
    end

    it 'changes transient attributes' do
      event.update_from!(other)

      updatable_attributes.each do |name, value|
        expect(event.send(name)).to eq value
      end
    end

    it 'calls #add_to_payload' do
      expect(event).to receive(:add_to_payload)
      event.update_from!(other)
    end
  end

  describe '#add_to_payload' do
    let(:initial_payload) { { 'competitors' => %w[Foo Bar] } }
    let(:other_payload) { { 'competitors' => %w[Bar Baz] } }

    let(:event) { create(:event, payload: initial_payload) }
    let(:other) { build(:event, payload: other_payload) }

    it 'updates existing payload' do
      event.update_from!(other)
      expect(event.payload).to eq other_payload
    end

    it 'assigns payload' do
      event = create(:event, payload: nil)
      event.update_from!(other)

      expect(event.payload).to eq other_payload
    end

    it 'doesn\'t overwrite payload with nil' do
      other = build(:event, payload: nil)
      event.update_from!(other)

      expect(event.payload).to eq initial_payload
    end
  end

  context 'callbacks' do
    it 'emits web socket event on create' do
      event = create(:event)
      expect(WebSocket::Client.instance)
        .to have_received(:emit)
        .with(WebSocket::Signals::EVENT_CREATED,
              id: event.id.to_s)
    end

    it 'emits web socket event on update' do
      allow_any_instance_of(Event).to receive(:emit_created)
      event = create(:event)
      event.assign_attributes(name: 'New name')
      event.save!
      expect(WebSocket::Client.instance)
        .to have_received(:emit)
        .with(WebSocket::Signals::EVENT_UPDATED,
              id: event.id.to_s,
              changes: { name: 'New name' })
    end

    it 'does not emit web socket event if no changes' do
      allow_any_instance_of(Event).to receive(:emit_created)
      event = create(:event)
      event.assign_attributes(updated_at: Time.now)
      event.save!
      expect(WebSocket::Client.instance)
        .not_to have_received(:emit)
        .with(WebSocket::Signals::EVENT_UPDATED, anything)
    end
  end
end
