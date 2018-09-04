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
      subject.name = 'Match winner'
      subject.validate
      expect(subject.priority).to eq(1)
    end
  end
end
