# frozen_string_literal: true

describe GraphQL, '#payment_methods' do
  let(:auth_customer) { create(:customer) }
  let(:payment_methods) { ::Payments::Withdraw::PAYMENT_METHODS }
  let(:context) { { current_customer: auth_customer } }
  let(:variables) { {} }
  let(:query) do
    %({ withdrawalMethods { name code note } })
  end
  let(:result) do
    ArcanebetSchema.execute(query,
                            context: context,
                            variables: variables)
  end

  let(:sample_payment_method) { result['data']['withdrawalMethods'].sample }
  let(:payment_method_code) { sample_payment_method['code'] }
  let(:payment_method_name) do
    I18n.t("payments.withdrawal.payment_methods.#{payment_method_code}.title",
           default: payment_method_code.humanize)
  end
  let(:payment_method_note) do
    I18n.t("payments.withdrawal.payment_methods.#{payment_method_code}.note",
           default: payment_method_code.humanize)
  end

  it 'returns list of all withdrawal methods' do
    expect(result['data']['withdrawalMethods'].length)
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
