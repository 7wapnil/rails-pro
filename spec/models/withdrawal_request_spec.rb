describe WithdrawalRequest, type: :model do
  it { is_expected.to belong_to(:actioned_by) }
end
