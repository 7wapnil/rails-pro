# frozen_string_literal: true

describe GraphQL, '#payment_methods' do
  let(:auth_customer) { create(:customer) }
  let!(:primary_currency) { create(:currency, :primary) }
  let(:payment_methods) { ::Payments::Withdraw::PAYMENT_METHODS }
  let(:context) { { current_customer: auth_customer } }
  let(:variables) { {} }
  let(:query) do
    %({ withdrawalMethods { name code note description } })
  end
  let(:result) do
    ArcanebetSchema.execute(query,
                            context: context,
                            variables: variables)
  end

  let(:sample_payment_method) { result['data']['withdrawalMethods'].sample }
  let(:payment_method_code) { sample_payment_method['code'] }
  let(:payment_method_name) do
    I18n.t("payments.withdrawals.payment_methods.#{payment_method_code}.title",
           default: payment_method_code.humanize)
  end
  let(:amount_range) do
    ::Withdrawals::PaymentMethodRangeSelector.call(
      customer: auth_customer,
      payment_method: payment_method_code
    )
  end
  let(:payment_method_note) do
    I18n.t(
      "payments.withdrawals.payment_methods.#{payment_method_code}.range",
      **amount_range,
      default: nil
    )
  end
  let(:payment_method_description) do
    I18n.t(
      "payments.withdrawals.payment_methods.#{payment_method_code}.description",
      default: nil
    )
  end

  it 'returns list of all withdrawal methods' do
    expect(result['data']['withdrawalMethods'].length)
      .to eq(payment_methods.length)
  end

  it 'has all required fields' do
    expect(sample_payment_method).to include(
      'name' => payment_method_name,
      'code' => payment_method_code,
      'note' => payment_method_note,
      'description' => payment_method_description
    )
  end
end
