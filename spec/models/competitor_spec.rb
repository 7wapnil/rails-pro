describe Competitor do
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:external_id) }

  it { is_expected.to have_many(:players) }
end
