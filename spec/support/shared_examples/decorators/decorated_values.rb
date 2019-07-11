# frozen_string_literal: true

shared_examples 'decorated amount', decorator: true do
  let(:formatted_amount) do
    helpers.number_with_precision(control_amount, precision: precision)
  end
  let(:expected_amount) { "#{formatted_amount} #{currency_symbol}".html_safe }

  it 'works' do
    expect(amount).to eq(expected_amount)
  end
end
