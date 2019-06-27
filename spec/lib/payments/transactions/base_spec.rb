# frozen_string_literal: true

describe Payments::Transactions::Base, type: :model do
  it { is_expected.to validate_presence_of(:method) }
  it { is_expected.to validate_presence_of(:customer) }
  it { is_expected.to validate_presence_of(:currency_code) }
  it { is_expected.to validate_presence_of(:amount) }
  it { expect(subject).to validate_numericality_of(:amount) }
end
