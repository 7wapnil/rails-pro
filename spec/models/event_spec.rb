describe Event do
  subject(:event) { described_class.new }

  let(:stubbed_subject) { described_class.new }

  it { is_expected.to belong_to(:title) }
  it { is_expected.to belong_to(:producer).class_name(Radar::Producer.name) }
  it { is_expected.to have_many(:markets) }
  it { is_expected.to have_many(:scoped_events) }
  it { is_expected.to have_many(:event_scopes).through(:scoped_events) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to allow_value(true, false).for(:active) }

  it { is_expected.to delegate_method(:name).to(:title).with_prefix }

  it_behaves_like 'updatable on duplicate'

  it 'returns details adapter' do
    expect(subject.details).to be_a(EventDetails::Base)
  end

  it 'updates on duplicate key' do
    event = create(:event, external_id: :test_external_id)
    event.name = 'New event name'
    described_class.create_or_update_on_duplicate(event)
    event = described_class.find_by!(external_id: :test_external_id)
    expect(event.name).to eq('New event name')
  end

  describe '.in_play' do
    it 'includes started and not finished events that are traded live' do
      event = create(:event,
                     start_at: 5.minutes.ago,
                     end_at: nil,
                     traded_live: true)

      expect(described_class.in_play).to include(event)
    end

    it 'doesn\'t include not started events' do
      event = create(:event,
                     start_at: 5.minutes.from_now,
                     end_at: nil,
                     traded_live: true)

      expect(described_class.in_play).not_to include(event)
    end

    it 'doesn\'t include finished events' do
      event = create(:event,
                     start_at: 1.hour.ago,
                     end_at: 5.minutes.ago,
                     traded_live: true)

      expect(described_class.in_play).not_to include(event)
    end

    it 'doesn\'t include events that are not traded live' do
      event = create(:event,
                     start_at: 5.minutes.ago,
                     end_at: nil,
                     traded_live: false)

      expect(described_class.in_play).not_to include(event)
    end

    it 'doesn\'t include events that started longer than 4 hours ago' do
      event = create(:event,
                     start_at: 245.minutes.ago,
                     end_at: nil,
                     traded_live: true)

      expect(described_class.in_play).not_to include(event)
    end
  end

  describe '.upcoming' do
    shared_examples 'upcoming event query' do
      it 'doesn\'t include started events' do
        event = create(:event, start_at: 5.minutes.ago)
        expect(described_class.upcoming).not_to include(event)
      end

      it 'doesn\'t include ended events' do
        event = create(:event, start_at: 1.hour.ago, end_at: 5.minutes.ago)
        expect(described_class.upcoming).not_to include(event)
      end

      it 'doesn\'t include events with :end_at in future' do
        event = create(:event, start_at: 1.hour.ago, end_at: 5.minutes.from_now)
        expect(described_class.upcoming).not_to include(event)
      end
    end

    context 'without arguments' do
      include_context 'upcoming event query'

      it 'includes not started events' do
        event = create(:event, start_at: 5.minutes.from_now, end_at: nil)
        expect(described_class.upcoming).to include(event)
      end
    end

    context 'with upper limit set' do
      include_context 'upcoming event query'

      let(:limit_start_at) { 10.minutes.from_now }

      it 'includes not started events in range' do
        event = create(:event, start_at: 5.minutes.from_now, end_at: nil)
        expect(described_class.upcoming(limit_start_at: limit_start_at))
          .to include(event)
      end

      it 'does not includes not started events outside of range' do
        event = create(:event, start_at: 15.minutes.from_now, end_at: nil)
        expect(described_class.upcoming(limit_start_at: limit_start_at))
          .not_to include(event)
      end
    end
  end

  describe '.past' do
    it 'includes prematch events that started in past' do
      event = create(
        :event,
        start_at: 5.minutes.ago,
        end_at: nil,
        traded_live: false
      )
      expect(described_class.past).to include(event)
    end

    it 'includes ended live events' do
      event = create(
        :event,
        start_at: 2.hours.ago,
        end_at: 5.minutes.ago,
        traded_live: true
      )
      expect(described_class.past).to include(event)
    end

    it 'doesn\'t include not started prematch events' do
      event = create(
        :event,
        start_at: 5.minutes.from_now,
        end_at: nil,
        traded_live: false
      )
      expect(described_class.past).not_to include(event)
    end

    it 'doesn\'t include not ended live events' do
      event = create(
        :event,
        start_at: 2.hours.ago,
        end_at: nil,
        traded_live: true
      )

      expect(described_class.past).not_to include(event)
    end
  end

  describe '.#upcoming? ' do
    shared_context 'frozen_time'

    it 'when end_at exist is not upcoming' do
      expect(build(:event, end_at: Time.zone.now)).not_to be_upcoming
    end

    it 'when start_at equals to now is not upcoming' do
      expect(
        build(:event, end_at: nil, start_at: Time.zone.now)
      ).not_to be_upcoming
    end

    it 'when start_at less than now is not upcoming ' do
      expect(
        build(:event, end_at: nil, start_at: Time.zone.now - 1.second)
      ).not_to be_upcoming
    end

    it 'when start_at more than now and missing end_at it is upcoming ' do
      expect(
        build(:event, end_at: nil, start_at: Time.zone.now + 1.second)
      ).to be_upcoming
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

    it 'is false when start_at later than 4 hours' do
      start_at = Event::START_AT_OFFSET_IN_HOURS.hours.ago - 1.minute
      event = create(:event,
                     start_at: start_at,
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
    let(:subject_event) { create(:event) }

    it 'fails with TypeError when not an Event argument is passed' do
      expect { subject_event.update_from!(:foo) }
        .to raise_error(TypeError, 'Passed \'other\' argument is not an Event')
    end

    it 'changes transient attributes' do
      subject_event.update_from!(other)

      updatable_attributes.each do |name, value|
        expect(subject_event.send(name)).to eq value
      end
    end

    it 'calls #add_to_payload' do
      expect(subject_event).to receive(:add_to_payload)
      subject_event.update_from!(other)
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

  describe '#alive?' do
    context 'without TRADED_LIVE' do
      let(:event) { build(:event, status: Event::SUSPENDED) }

      it { expect(event).not_to be_alive }
    end

    context 'with SUSPENDED status' do
      let(:event) do
        build(:event, traded_live: true, status: Event::SUSPENDED)
      end

      it { expect(event).to be_alive }
    end

    context 'in play' do
      let(:event) { build(:event, :live) }

      it { expect(event).to be_alive }
    end
  end
end
