describe Odd do
  it { should define_enum_for(:status) }

  it { should belong_to(:market) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:status) }
  it { should validate_numericality_of(:value).is_greater_than(0) }

  it 'validates value on create is status active' do
    subject.status = 1
    should validate_presence_of(:value).on(:create)
  end

  it 'not validates value on create if status inactive' do
    subject.status = 0
    should_not validate_presence_of(:value).on(:create)
  end

  it_behaves_like 'has unique :external_id' do
    subject { create(:odd) }
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
      allow_any_instance_of(Odd).to receive(:emit_created)
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
