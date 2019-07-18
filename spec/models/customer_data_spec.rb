# frozen_string_literal: true

describe CustomerData do
  it { is_expected.to belong_to(:customer) }
end
