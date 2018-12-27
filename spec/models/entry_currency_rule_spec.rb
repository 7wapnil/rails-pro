describe EntryCurrencyRule do
  it { is_expected.to belong_to(:currency) }

  it { is_expected.to validate_presence_of(:kind) }
end
