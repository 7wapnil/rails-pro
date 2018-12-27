describe BettingLimit do
  it { is_expected.to belong_to(:customer) }
  it { is_expected.to belong_to(:title) }

  it { is_expected.to validate_presence_of(:customer) }
end
