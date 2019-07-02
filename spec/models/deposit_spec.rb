# frozen_string_literal: true

describe Deposit, type: :model do
  subject(:deposit) { described_class.new }

  it { is_expected.to have_one(:entry_request) }
  it { is_expected.to have_one(:entry) }
  it { is_expected.to belong_to(:customer_bonus) }
end
