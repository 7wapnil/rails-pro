describe Event, type: :model do
  it { should belong_to(:discipline) }
  it { should have_many(:markets) }
  it { should have_many(:scoped_events) }
  it { should have_many(:event_scopes).through(:scoped_events) }

  it { should validate_presence_of(:name) }

  it { should delegate_method(:name).to(:discipline).with_prefix }
end
