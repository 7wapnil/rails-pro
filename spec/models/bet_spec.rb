describe Bet do
  subject { build(:bet) }

  it { should define_enum_for(:status) }

  it { should belong_to(:customer) }
  it { should belong_to(:odd) }
  it { should belong_to(:currency) }

  it { should have_one(:entry) }
  it { should have_one(:entry_request) }

  it do
    should validate_numericality_of(:odd_value)
      .is_equal_to(subject.odd.value)
      .on(:create)
  end

  it { should allow_value(true, false).for(:result) }

  it do
    should validate_numericality_of(:void_factor)
      .is_greater_than_or_equal_to(0)
      .is_less_than_or_equal_to(1)
  end
end
