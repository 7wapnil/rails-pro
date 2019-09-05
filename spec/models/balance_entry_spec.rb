# frozen_string_literal: true

describe BalanceEntry do
  it { is_expected.to belong_to(:balance) }
  it { is_expected.to belong_to(:entry) }
  it { is_expected.to have_one(:customer_bonus).inverse_of(:balance_entry) }

  it { is_expected.to validate_presence_of(:amount) }

  include_examples 'precionable up to 12 digit', :amount
  include_examples 'precionable up to 12 digit', :balance_amount_after
end
