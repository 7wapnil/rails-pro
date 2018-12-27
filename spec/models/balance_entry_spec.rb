describe BalanceEntry do
  it { is_expected.to belong_to(:balance) }
  it { is_expected.to belong_to(:entry) }

  it { is_expected.to validate_presence_of(:amount) }
end
