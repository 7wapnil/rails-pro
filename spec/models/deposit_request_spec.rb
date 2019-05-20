# frozen_string_literal: true

describe DepositRequest, type: :model do
  subject(:deposit_request) { described_class.new }

  it { is_expected.to have_one(:entry_request) }
  it { is_expected.to have_one(:entry) }
  it { is_expected.to belong_to(:customer_bonus) }
end
