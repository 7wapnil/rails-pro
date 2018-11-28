describe Market do
  it { should define_enum_for(:status) }

  it { should belong_to(:event) }
  it { should have_many(:odds) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:priority) }
  it { should validate_presence_of(:status) }

  context 'callbacks' do
    it 'calls priority definition before validation' do
      allow(subject).to receive(:define_priority)
      subject.name = 'New name'
      subject.validate
      expect(subject).to have_received(:define_priority)
    end

    it 'does not call priority definition before save if name not changed' do
      allow(subject).to receive(:define_priority)
      subject.validate
      expect(subject).not_to have_received(:define_priority)
    end
  end

  context 'priority' do
    it 'defines 1 priority by default' do
      subject.name = 'Unknown name'
      subject.validate
      expect(subject.priority).to eq(1)
    end

    %w[Winner 1x2].each do |market_name|
      it "defines 1 priority for market name '#{market_name}'" do
        subject.name = market_name
        subject.validate
        expect(subject.priority).to eq(0)
      end
    end
  end

  [
    %i[active cancelled],
    %i[inactive cancelled],
    %i[settled active],
    %i[settled inactive],
    %i[settled suspended],
    %i[cancelled active],
    %i[cancelled inactive],
    %i[cancelled suspended],
    %i[cancelled settled]
  ].each do |initial_state, new_state|
    it "raises error on switching from '#{initial_state}' to '#{new_state}'" do
      market = create(:market, status: Market.statuses[initial_state])
      market.status = Market.statuses[new_state]
      expect(market.valid?).to be_falsey
      error_msg = I18n.t('errors.messages.wrong_market_state',
                         initial_state: initial_state,
                         new_state: new_state)
      expect(market.errors[:status][0]).to eq(error_msg)
    end
  end

  [
    %i[suspended settled],
    %i[suspended cancelled],
    %i[active settled],
    %i[active inactive],
    %i[active suspended],
    %i[active handed_over],
    %i[inactive active],
    %i[inactive settled],
    %i[inactive handed_over],
    %i[suspended active],
    %i[suspended inactive],
    %i[suspended handed_over],
    %i[settled handed_over],
    %i[cancelled handed_over],
    %i[inactive suspended]
  ].each do |initial_state, new_state|
    it "allows switching from '#{initial_state}' to '#{new_state}'" do
      market = create(:market, status: Market.statuses[initial_state])
      market.status = Market.statuses[new_state]
      market.valid?
      expect(market.errors[:status]).to be_blank
    end
  end

  it 'emits web socket event on create' do
    market = create(:market)
    expect(WebSocket::Client.instance)
      .to have_received(:emit)
      .with(WebSocket::Signals::MARKET_CREATED,
            id: market.id.to_s,
            eventId: market.event_id.to_s)
  end

  it 'emits web socket event on update' do
    allow_any_instance_of(Market).to receive(:emit_created)
    market = create(:market)
    market.assign_attributes(name: 'New name',
                             status: Market.statuses[:active])
    market.save!
    expect(WebSocket::Client.instance)
      .to have_received(:emit)
      .with(WebSocket::Signals::MARKET_UPDATED,
            id: market.id.to_s,
            eventId: market.event_id.to_s,
            changes: {
              name: 'New name',
              status: 'active'
            })
  end
end
