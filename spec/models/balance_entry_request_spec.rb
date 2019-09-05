require 'rails_helper'

describe BalanceEntryRequest, type: :model do
  it { is_expected.to belong_to(:entry_request) }
  it { is_expected.to belong_to(:balance_entry) }
  it { is_expected.to validate_presence_of(:amount) }
  it { is_expected.to validate_numericality_of(:amount) }

  it { expect(described_class.kinds).to eq(Balance.kinds) }
  it { is_expected.to have_one(:balance).through(:balance_entry) }

  include_examples 'precionable up to 12 digit', :amount
end
