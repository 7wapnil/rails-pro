describe EntryCurrencyRule do
  it_should_behave_like 'audit model', factory: :entry_currency_rule

  it { should belong_to(:currency) }

  it { should validate_presence_of(:kind) }
end
