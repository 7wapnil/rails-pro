describe CustomerNote do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:customer) }

  it { is_expected.to validate_presence_of(:content) }

  it { is_expected.to act_as_paranoid }
end
