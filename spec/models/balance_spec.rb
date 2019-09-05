# frozen_string_literal: true

describe Balance do
  subject(:balance) { described_class.new }

  it { is_expected.to belong_to(:wallet) }
  it { is_expected.to have_many(:balance_entries) }
  it { expect(balance).to validate_numericality_of(:amount) }

  include_examples 'precionable up to 12 digit', :amount
end
