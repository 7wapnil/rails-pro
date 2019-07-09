# frozen_string_literal: true

describe GraphQL, '#payment_methods' do
  let(:auth_customer) { create(:customer) }
  let(:payment_methods) { ::Payments::Deposit::PAYMENT_METHODS }
  let(:context) { { current_customer: auth_customer } }
  let(:variables) { {} }
  let(:query) do
    %({ depositMethods { name code note } })
  end
  let(:result) do
    ArcanebetSchema.execute(query,
                            context: context,
                            variables: variables)
  end

  let(:sample_payment_method) { result['data']['depositMethods'].sample }
  let(:payment_method_code) { sample_payment_method['code'] }
  let(:payment_method_name) do
    I18n.t("payments.deposit.payment_methods.#{payment_method_code}.title",
           default: payment_method_code.humanize)
  end
  let(:payment_method_note) do
    I18n.t("payments.deposit.payment_methods.#{payment_method_code}.note",
           default: nil)
  end

  it 'returns list of all deposit methods' do
    expect(result['data']['depositMethods'].length)
      .to eq(payment_methods.length)
  end

  it 'has all required fields' do
    expect(sample_payment_method).to include(
      'name' => payment_method_name,
      'code' => payment_method_code,
      'note' => payment_method_note
    )
  end
end
