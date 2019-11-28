describe GraphQL, '#user' do
  let(:request) do
    OpenStruct.new(remote_ip: Faker::Internet.ip_v4_address)
  end
  let(:customer) { create(:customer) }
  let!(:wallet) { create(:wallet, :non_primary_fiat, customer: customer) }
  let!(:crypto_wallet) { create(:wallet, :crypto, customer: customer) }
  let(:context) { { request: request, current_customer: customer } }
  let(:variables) { {} }
  let(:result) do
    ArcanebetSchema.execute(query,
                            context: context,
                            variables: variables)
  end

  let(:response) { result['data']['user'] }

  context 'basic fields' do
    let(:query) do
      %(query {
        user {
          id
          email
          username
          verified
          regular
          availableWithdrawalMethods { note }
        }
      })
    end

    it 'returns user data on query' do
      expect(response).not_to be_nil
    end

    it 'returns requested attributes' do
      expect(response).to include('id' => customer.id.to_s,
                                  'verified' => true,
                                  'regular' => true,
                                  'availableWithdrawalMethods' => [])
    end
  end

  context 'with available withdrawal methods' do
    let(:credit_card_deposit) { create(:deposit, :credit_card) }
    let(:credit_card_entry_request) do
      create(:entry_request, :with_entry,
             customer: customer,
             currency: wallet.currency,
             status: EntryRequest::SUCCEEDED,
             mode: EntryRequest::CREDIT_CARD,
             origin: credit_card_deposit)
    end
    let(:duplicated_credit_card_entry_request) do
      create(:entry_request, :with_entry,
             customer: customer,
             currency: wallet.currency,
             status: EntryRequest::SUCCEEDED,
             mode: EntryRequest::CREDIT_CARD,
             origin: create(:deposit, details: credit_card_deposit.details))
    end
    let(:second_credit_card_entry_request) do
      create(:entry_request, :with_entry,
             customer: customer,
             currency: wallet.currency,
             status: EntryRequest::SUCCEEDED,
             mode: EntryRequest::CREDIT_CARD,
             origin: create(:deposit, :credit_card))
    end
    let(:skrill_entry_request) do
      create(:entry_request, :with_entry,
             customer: customer,
             currency: wallet.currency,
             status: EntryRequest::SUCCEEDED,
             mode: EntryRequest::SKRILL,
             origin: create(:deposit, :skrill))
    end
    let(:second_skrill_entry_request) do
      create(:entry_request, :with_entry,
             customer: customer,
             currency: wallet.currency,
             status: EntryRequest::SUCCEEDED,
             mode: EntryRequest::SKRILL,
             origin: create(:deposit, :skrill))
    end
    let(:neteller_entry_request) do
      create(:entry_request, :with_entry,
             customer: customer,
             currency: wallet.currency,
             status: EntryRequest::SUCCEEDED,
             mode: EntryRequest::NETELLER,
             origin: create(:deposit, :neteller))
    end
    let(:second_neteller_entry_request) do
      create(:entry_request, :with_entry,
             customer: customer,
             currency: wallet.currency,
             status: EntryRequest::SUCCEEDED,
             mode: EntryRequest::NETELLER,
             origin: create(:deposit, :neteller))
    end
    let(:bitcoin_deposit) { create(:deposit, :bitcoin) }
    let(:bitcoin_entry_request) do
      create(:entry_request, :with_entry,
             customer: customer,
             currency: crypto_wallet.currency,
             status: EntryRequest::SUCCEEDED,
             mode: EntryRequest::BITCOIN,
             origin: bitcoin_deposit)
    end
    let(:duplicated_bitcoin_entry_request) do
      create(:entry_request, :with_entry,
             customer: customer,
             currency: crypto_wallet.currency,
             status: EntryRequest::SUCCEEDED,
             mode: EntryRequest::BITCOIN,
             origin: create(:deposit, details: bitcoin_deposit.details))
    end
    let(:idebit_entry_request) do
      create(:entry_request, :with_entry,
             customer: customer,
             currency: wallet.currency,
             status: EntryRequest::SUCCEEDED,
             mode: EntryRequest::IDEBIT,
             origin: create(:deposit, :idebit))
    end

    let!(:successful_entry_requests) do
      [
        duplicated_credit_card_entry_request,
        second_credit_card_entry_request,
        skrill_entry_request,
        second_skrill_entry_request,
        neteller_entry_request,
        second_neteller_entry_request,
        duplicated_bitcoin_entry_request,
        idebit_entry_request
      ]
    end

    let!(:currency_rule) do
      create(:entry_currency_rule, :withdraw, currency: wallet.currency)
    end

    let(:query) do
      %(query {
        user {
          id
          availableWithdrawalMethods {
            id
            code
            name
            note
            description
            currencyCode
            currencyKind
            details {
              ... on PaymentMethodCreditCard {
                id
                title
                holderName
                lastFourDigits
                tokenId
                maskedAccountNumber
              }
              ... on PaymentMethodBitcoin {
                id
                title
                isEditable
              }
              ... on PaymentMethodSkrill {
                id
                title
                userPaymentOptionId
                name
              }
              ... on PaymentMethodNeteller {
                id
                title
                userPaymentOptionId
                name
              }
              ... on PaymentMethodIdebit {
                id
                title
                userPaymentOptionId
                name
              }
            }
          }
        }
      })
    end

    let(:response_methods) { response['availableWithdrawalMethods'] }
    let(:result_methods_ids) { response_methods.map { |item| item['id'].to_i } }

    let(:details) { OpenStruct.new(object.deposit.details) }
    let(:name) do
      I18n.t("payments.withdrawals.payment_methods.#{object.mode}.title")
    end

    let(:note) do
      I18n.t("payments.withdrawals.payment_methods.#{object.mode}.range",
             min_amount: currency_rule.max_amount.abs,
             max_amount: currency_rule.min_amount.abs,
             code: control_wallet.currency.code)
    end

    let(:description) do
      I18n
        .t("payments.withdrawals.payment_methods.#{object.mode}.description")
    end

    let(:response_fields) do
      response_methods.find { |method| method['id'] == object.id.to_s }
    end

    before do
      create(:entry_request,
             customer: customer,
             currency: wallet.currency,
             status: EntryRequest::SUCCEEDED,
             mode: EntryRequest::CREDIT_CARD,
             origin: create(:deposit, :credit_card))
      create(:entry_request, :with_entry,
             customer: customer,
             currency: wallet.currency,
             status: EntryRequest::SUCCEEDED,
             mode: EntryRequest::CREDIT_CARD)
      create(:entry_request, :with_entry,
             customer: customer,
             currency: wallet.currency,
             status: EntryRequest::SUCCEEDED,
             mode: EntryRequest::SKRILL)
      create(:entry_request, :with_entry,
             customer: customer,
             currency: wallet.currency,
             status: EntryRequest::SUCCEEDED,
             mode: EntryRequest::NETELLER)
      create(:entry_request, :with_entry,
             customer: customer,
             currency: wallet.currency,
             status: EntryRequest::SUCCEEDED,
             mode: EntryRequest::BITCOIN)
      create(:entry_request, :with_entry,
             customer: customer,
             currency: wallet.currency,
             status: EntryRequest::SUCCEEDED,
             mode: EntryRequest::IDEBIT)
    end

    it 'returns all available withdrawal methods' do
      expect(result_methods_ids)
        .to match_array(successful_entry_requests.map(&:id))
    end

    context 'credit card fields' do
      let(:object) { second_credit_card_entry_request }
      let(:control_wallet) { wallet }
      let(:title) { "**** #{details.masked_account_number.last(4)}" }

      it 'are returned correct' do
        expect(response_fields).to include(
          'id' => object.id.to_s,
          'code' => object.mode,
          'name' => name,
          'note' => note,
          'description' => description,
          'currencyCode' => nil,
          'currencyKind' => Currency::FIAT,
          'details' => {
            'id' => object.id.to_s,
            'title' => title,
            'holderName' => details.holder_name,
            'lastFourDigits' => details.masked_account_number.last(4),
            'tokenId' => details.token_id,
            'maskedAccountNumber' => details.masked_account_number
          }
        )
      end
    end

    context 'bitcoin fields' do
      let(:object) { duplicated_bitcoin_entry_request }
      let(:control_wallet) { crypto_wallet }
      let(:title) { ::Payments::Methods::BITCOIN.humanize }

      it 'are returned correct' do
        expect(response_fields).to include(
          'id' => object.id.to_s,
          'code' => object.mode,
          'name' => name,
          'note' => nil,
          'description' => description,
          'currencyCode' => 'mTBTC',
          'currencyKind' => Currency::CRYPTO,
          'details' => {
            'id' => object.id.to_s,
            'title' => title,
            'isEditable' => true
          }
        )
      end
    end

    context 'skrill fields' do
      let(:object) { skrill_entry_request }
      let(:control_wallet) { wallet }
      let(:title) { details.name }

      it 'are returned correct' do
        expect(response_fields).to include(
          'id' => object.id.to_s,
          'code' => object.mode,
          'name' => name,
          'note' => note,
          'description' => nil,
          'currencyCode' => nil,
          'currencyKind' => Currency::FIAT,
          'details' => {
            'id' => object.id.to_s,
            'title' => title,
            'name' => details.name,
            'userPaymentOptionId' => details.user_payment_option_id
          }
        )
      end
    end

    context 'neteller fields' do
      let(:object) { neteller_entry_request }
      let(:control_wallet) { wallet }
      let(:title) { details.name }

      it 'are returned correct' do
        expect(response_fields).to include(
          'id' => object.id.to_s,
          'code' => object.mode,
          'name' => name,
          'note' => note,
          'description' => nil,
          'currencyCode' => nil,
          'currencyKind' => Currency::FIAT,
          'details' => {
            'id' => object.id.to_s,
            'title' => title,
            'name' => details.name,
            'userPaymentOptionId' => details.user_payment_option_id
          }
        )
      end
    end

    context 'iDebit fields' do
      let(:object) { idebit_entry_request }
      let(:control_wallet) { wallet }
      let(:title) { details.name }

      it 'are returned correct' do
        expect(response_fields).to include(
          'id' => object.id.to_s,
          'code' => object.mode,
          'name' => name,
          'note' => note,
          'description' => nil,
          'currencyCode' => nil,
          'currencyKind' => Currency::FIAT,
          'details' => {
            'id' => object.id.to_s,
            'title' => title,
            'name' => details.name,
            'userPaymentOptionId' => details.user_payment_option_id
          }
        )
      end
    end
  end
end
