require 'rails_helper'

RSpec.describe BalanceEntryRequest, type: :model do
  it { is_expected.to belong_to(:entry_request) }
  it { is_expected.to belong_to(:balance_entry) }
  it { is_expected.to validate_presence_of(:amount) }
  it { is_expected.to validate_numericality_of(:amount) }

  it { expect(described_class.kinds).to eq(Balance.kinds) }
end
