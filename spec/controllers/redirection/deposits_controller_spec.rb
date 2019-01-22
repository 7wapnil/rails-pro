describe Redirection::DepositsController do
  describe '#initiate' do
    subject do
      get :initiate,
          params: { token: JwtService.encode(id: customer.id),
                    currency_code: wallet.currency.code,
                    amount: amount,
                    bonus_code: bonus.code }
    end

    let(:amount) { Faker::Number.number 2 }
    let(:bonus) { build(:bonus) }
    let(:wallet) { build(:wallet) }
    let(:customer) { wallet.customer }
    let(:gateway_url) { Faker::Internet.url }
    let(:frontend_url) { Faker::Internet.url }
    let(:entry_request) do
      create(:entry_request, status: EntryRequest::INITIAL)
    end
    let(:valid_params) do
      {
        customer: customer,
        currency: wallet.currency,
        amount: amount.to_d,
        bonus_code: bonus.code
      }
    end

    before do
      allow(Deposits::InitiateHostedDepositService)
        .to receive(:call) {
          entry_request
        }
      allow(Deposits::EntryRequestUrlService)
        .to receive(:call)
    end

    it 'calls service to generate entry request' do
      allow(Deposits::InitiateHostedDepositService).to receive(:call).with(
        valid_params
      ).once
    end

    it 'calls service to represent entry request state with url' do
      allow(::Deposits::EntryRequestUrlService).to receive(:call)
        .with(
          entry_request: entry_request
        ).once
    end

    context 'when corrupted data received' do
      let(:invalid_token)  do
        JwtService.encode(id: customer.id) + 'invalidtokenpart'
      end
      let(:non_existing_customer_id) { customer.ids.max + 1 }
      let(:invalid_currency_code) { wallet.currency.code + 'RUBBISH' }
      let(:callback_url) { Faker::Internet.url }

      before do
        allow(Deposit::CallbackUrl)
          .to receive(:for).with(:something_went_wrong) { callback_url }
      end

      it 'redirects to callback url on invalid customer id ' do
        expect(
          get(
            :initiate,
            params: valid_params
                        .update(token: JwtService.encode(id: customer.id + 1))
          )
        ).to redirect_to(callback_url)
      end

      it 'redirects to callback url on invalid currency' do
        expect(
          get(
            :initiate,
            params: valid_params.update(currency: invalid_currency_code)
          )
        ).to redirect_to(callback_url)
      end

      it 'redirects to callback url on invalid token' do
        expect(
          get(:initiate,
              params: valid_params.update(token: invalid_token))
        ).to redirect_to(callback_url)
      end
    end

    %i[success error pending back].each do |state|
      context "When #{state} callback request made" do
        let(:callback_url) { Faker::Internet.url }

        before do
          allow(Deposit::CallbackUrl)
            .to receive(:for).with(state) { callback_url }
        end

        it "redirects #{state} to callback url with state" do
          expect(get(state)).to redirect_to(callback_url)
        end
      end
    end

    it 'responds to webhook endpoint with ok' do
      get(:webhook)
      expect(response).to have_http_status(:ok)
    end
  end
end
