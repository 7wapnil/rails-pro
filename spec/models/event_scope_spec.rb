describe EventScope do
  it { is_expected.to belong_to(:title) }
  it { is_expected.to have_many(:scoped_events) }
  it { is_expected.to have_many(:events).through(:scoped_events) }

  # it { should define_enum_for(:kind) }

  it { is_expected.to validate_presence_of(:name) }

  it_behaves_like 'updatable on duplicate'
end
