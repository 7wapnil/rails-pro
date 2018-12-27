describe Label do
  it { is_expected.to have_many(:customers) }

  it { is_expected.to validate_presence_of(:name) }

  it { is_expected.to act_as_paranoid }
end
