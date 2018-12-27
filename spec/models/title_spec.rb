describe Title do
  it { is_expected.to have_many(:events) }
  it { is_expected.to have_many(:event_scopes) }

  # it { should define_enum_for(:kind) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_uniqueness_of(:name) }

  it_behaves_like 'updatable on duplicate'
end
