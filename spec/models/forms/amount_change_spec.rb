# frozen_string_literal: true

describe Forms::AmountChange do
  subject(:form) { described_class.new(model, params) }

  let(:model) { build(:balance) }
  let(:entry_request) do
    build(:entry_request, real_money_amount: rand(10..100.0))
  end
  let(:params) do
    { request: entry_request }
  end

  context 'with wallet' do
    let(:model) { build(:wallet) }

    it do
      expect(form).to validate_numericality_of(:amount_increment)
    end
  end
end
