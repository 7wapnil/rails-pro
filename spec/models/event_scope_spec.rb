describe EventScope do
  it { should belong_to(:title) }
  it { should have_many(:scoped_events) }
  it { should have_many(:events).through(:scoped_events) }

  it { should define_enum_for(:kind) }

  it { should validate_presence_of(:name) }
end
