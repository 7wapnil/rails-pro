describe Title do
  it { is_expected.to have_many(:events) }
  it { is_expected.to have_many(:event_scopes) }

  it { is_expected.to validate_presence_of(:external_name) }
  it { is_expected.to validate_uniqueness_of(:external_name) }

  it_behaves_like 'updatable on duplicate'
end
