describe Market do
  it { should define_enum_for(:status) }

  it { should belong_to(:event) }
  it { should have_many(:odds) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:priority) }
  it { should validate_presence_of(:status) }

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
