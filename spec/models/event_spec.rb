# frozen_string_literal: true

describe Event do
  subject(:event) { build(:event) }

  let(:stubbed_subject) { described_class.new }

  it { is_expected.to belong_to(:title) }
  it { is_expected.to belong_to(:producer).class_name(Radar::Producer.name) }
  it { is_expected.to have_many(:markets) }
  it { is_expected.to have_many(:scoped_events) }
  it { is_expected.to have_many(:event_scopes).through(:scoped_events) }
  it { is_expected.to have_many(:competitors) }
  it { is_expected.to have_many(:players).through(:competitors) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to allow_value(true, false).for(:active) }

  it { is_expected.to delegate_method(:name).to(:title).with_prefix }

  it_behaves_like 'updatable on duplicate'

  it 'updates on duplicate key' do
    event = create(:event, external_id: :test_external_id)
    event.name = 'New event name'
    described_class.create_or_update_on_duplicate(event)
    event = described_class.find_by!(external_id: :test_external_id)
    expect(event.name).to eq('New event name')
  end

  describe '.in_play' do
    it 'includes started and suspended events that are traded live' do
      event = create(
        :event,
        status: Event::IN_PLAY_STATUSES.sample,
        traded_live: true
      )

      expect(described_class.in_play).to include(event)
    end

    it 'doesn\'t include not started or suspended events' do
      event_status =
        Event::STATUSES.values.without(*Event::IN_PLAY_STATUSES).sample
      event = create(
        :event,
        status: event_status,
        traded_live: true
      )

      expect(described_class.in_play).not_to include(event)
    end

    it 'doesn\'t include events that are not traded live' do
      event = create(
        :event,
        status: Event::IN_PLAY_STATUSES.sample,
        traded_live: false
      )

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
    include_context 'frozen_time'

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
    it 'is true when started or suspended and is traded live' do
      event = create(:event,
                     status: Event::IN_PLAY_STATUSES.sample,
                     traded_live: true)

      expect(event.in_play?).to be true
    end

    it 'is false when not started or suspended' do
      event_status =
        Event::STATUSES.values.without(*Event::IN_PLAY_STATUSES).sample
      event = create(:event,
                     status: event_status,
                     traded_live: true)

      expect(event.in_play?).not_to be true
    end

    it 'is false when not traded live' do
      event = create(:event,
                     status: Event::IN_PLAY_STATUSES.sample,
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
  end

  describe '#to_s' do
    it 'works' do
      expect(event.to_s).to eq(event.name)
    end
  end
end
