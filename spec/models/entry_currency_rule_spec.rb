describe EntryCurrencyRule do
  it { should belong_to(:currency) }

  it { should validate_presence_of(:kind) }
end
