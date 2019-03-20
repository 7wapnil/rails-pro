require './db/prime/prime_generator'

describe PrimeGenerator do

  let(:enough_scopes) { 6 }
  let(:enough_past_events) { 10 }
  let(:enough_live_events) { 5 }
  let(:enough_upcoming_events) { 10 }
  let(:enough_entries) { 15 }
  let(:enough_bets) { 10 }
  let(:enough_customers) { 20 }

  before :all do
    described_class.new.generate
  end

  %w[Football CS:GO].each do |name|
    it "ensures #{name} title exists" do
      expect(Title.find_by(name: name)).to be_present
    end
  end

  %w[LIVE_PROVIDER PREMATCH_PROVIDER].each do |type|
    it "ensures #{type} exists" do
      id = Radar::Producer.const_get(type + '_ID')
      expect(Radar::Producer.find(id)).to be_present
    end
  end

  %w[tournament category].each do |kind|
    it "ensures there are enough #{kind.pluralize}" do
      expect(EventScope.where(kind: kind).count).to be >= enough_scopes
    end
  end

  it 'generates past events' do
    expect(Event.past.count).to be >= enough_past_events
  end

  it 'generates live events' do
    expect(Event.in_play.count).to be >= enough_live_events
  end

  it 'generates upcoming events' do
    expect(Event.upcoming.count).to be >= enough_upcoming_events
  end

  it 'generates entries' do
    expect(Entry.count).to be >= enough_entries
  end
end
