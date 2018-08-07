describe Bet do
  it { should define_enum_for(:status) }

  it { should belong_to(:customer) }
  it { should belong_to(:odd) }
  it { should belong_to(:currency) }

  it { should have_one(:entry) }
  it { should have_one(:entry_request) }
end
