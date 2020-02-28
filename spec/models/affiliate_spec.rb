describe Affiliate do
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:b_tag) }
  it { is_expected.to validate_presence_of(:sports_revenue_share) }
  it { is_expected.to validate_presence_of(:casino_revenue_share) }
  it { is_expected.to validate_presence_of(:cost_per_acquisition) }

  it do
    expect(subject)
      .to validate_numericality_of(:sports_revenue_share)
      .is_greater_than_or_equal_to(0)
  end

  it do
    expect(subject)
      .to validate_numericality_of(:casino_revenue_share)
      .is_greater_than_or_equal_to(0)
  end

  it do
    expect(subject)
      .to validate_numericality_of(:cost_per_acquisition)
      .is_greater_than_or_equal_to(0)
  end
end
