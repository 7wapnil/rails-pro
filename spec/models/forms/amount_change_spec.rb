# frozen_string_literal: true

describe Forms::AmountChange do
  subject(:form) { described_class.new(model, params) }

  let(:model) { build(:balance) }
  let(:entry_request) { build(:entry_request) }
  let(:params) do
    { amount: rand(10..100.0), request: entry_request }
  end

  it do
    expect(form)
      .to validate_numericality_of(:amount)
      .is_greater_than_or_equal_to(0)
      .with_message(
        I18n.t('errors.messages.not_negative')
      )
  end

  context 'with wallet' do
    let(:model) { build(:wallet) }

    it do
      expect(form)
        .to validate_numericality_of(:amount)
        .is_greater_than_or_equal_to(0)
        .with_message(
          I18n.t('errors.messages.not_negative')
        )
    end
  end
end
