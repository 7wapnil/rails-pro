describe EntryCurrencyRule do
  it { is_expected.to belong_to(:currency) }

  it { is_expected.to validate_presence_of(:kind) }

  include_examples 'precionable up to 12 digit', :min_amount
  include_examples 'precionable up to 12 digit', :max_amount
end
