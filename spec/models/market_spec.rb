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

    it 'defines 0 priority by default' do
      subject.name = 'Unknown name'
      subject.validate
      expect(subject.priority).to eq(0)
    end

    it 'defines 1 priority for match winner market' do
      subject.name = 'Match - winner'
      subject.validate
      expect(subject.priority).to eq(1)
    end
  end

  [
    %i[active settled],
    %i[active cancelled],
    %i[inactive suspended],
    %i[inactive cancelled],
    %i[suspended settled],
    %i[suspended cancelled],
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
    %i[cancelled handed_over]
  ].each do |initial_state, new_state|
    it "allows switching from '#{initial_state}' to '#{new_state}'" do
      market = create(:market, status: Market.statuses[initial_state])
      market.status = Market.statuses[new_state]
      market.valid?
      expect(market.errors[:status]).to be_blank
    end
  end
end
