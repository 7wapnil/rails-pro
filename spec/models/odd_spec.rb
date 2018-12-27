describe Odd do
  # it { should define_enum_for(:status) }
  subject(:odd) { described_class.new }

  it { is_expected.to belong_to(:market) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:status) }
  it { is_expected.to validate_numericality_of(:value).is_greater_than(0) }

  it 'validates value on create is status active' do
    odd.status = Odd::ACTIVE
    expect(odd).to validate_presence_of(:value).on(:create)
  end

  it 'not validates value on create if status inactive' do
    odd.status = Odd::INACTIVE
    expect(odd).not_to validate_presence_of(:value).on(:create)
  end

  context 'callbacks' do
    it 'emits web socket event on create' do
      odd = create(:odd)
      expect(WebSocket::Client.instance)
        .to have_received(:emit)
        .with(WebSocket::Signals::ODD_CREATED,
              id: odd.id.to_s,
              marketId: odd.market.id.to_s,
              eventId: odd.market.event_id.to_s)
    end

    it 'emits web socket event on update' do
      allow_any_instance_of(described_class).to receive(:emit_created)
      odd = create(:odd)
      odd.assign_attributes(value: 1.99)
      odd.save!
      expect(WebSocket::Client.instance)
        .to have_received(:emit)
        .with(WebSocket::Signals::ODD_UPDATED,
              id: odd.id.to_s,
              marketId: odd.market.id.to_s,
              eventId: odd.market.event_id.to_s,
              changes: { value: 1.99 })
    end
  end
end
