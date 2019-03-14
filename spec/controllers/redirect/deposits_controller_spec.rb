describe Redirect::DepositsController do
  describe '#initiate' do
    subject do
      get :initiate,
          params: { token: JwtService.encode(id: customer.id),
                    currency_code: wallet.currency.code,
                    amount: amount,
                    bonus_code: bonus.code }
    end

    let(:amount) { Faker::Number.decimal(2, 2).to_d }
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
        currency_code: wallet.currency.code,
        amount: amount,
        bonus_code: bonus.code
      }
    end

    before do
      allow(ENV)
        .to receive(:[])
        .with('FRONTEND_URL')
        .and_return(frontend_url)
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
      let(:generic_error_callback_url) { Faker::Internet.url }
      let(:error_callback_url) { Faker::Internet.url }
      let(:deposit_attempts_exceeded_callback_url) { Faker::Internet.url }

      before do
        allow(Deposits::CallbackUrl)
          .to receive(:for)
          .with(Deposits::CallbackUrl::SOMETHING_WENT_WRONG)
          .and_return(generic_error_callback_url)
        allow(Deposits::CallbackUrl)
          .to receive(:for)
          .with(Deposits::CallbackUrl::ERROR)
          .and_return(error_callback_url)
        allow(Deposits::CallbackUrl)
          .to receive(:for)
          .with(Deposits::CallbackUrl::DEPOSIT_ATTEMPTS_EXCEEDED)
          .and_return(deposit_attempts_exceeded_callback_url)
      end

      it 'redirects to callback url on invalid customer id ' do
        expect(
          get(
            :initiate,
            params: valid_params
                        .update(token: JwtService.encode(id: customer.id + 1))
          )
        ).to redirect_to(error_callback_url)
      end

      it 'redirects to callback url on invalid currency' do
        expect(
          get(
            :initiate,
            params: valid_params.update(currency: invalid_currency_code)
          )
        ).to redirect_to(error_callback_url)
      end

      it 'redirects to callback url on invalid token' do
        expect(
          get(:initiate,
              params: valid_params.update(token: invalid_token))
        ).to redirect_to(error_callback_url)
      end
    end

    context 'when customer deposit attempts exceeded' do
      let(:callback_url) { Faker::Internet.url }
      let(:valid_token) { JwtService.encode(id: customer.id) }

      before do
        allow(::Deposits::CallbackUrl)
          .to receive(:for)
          .with(Deposits::CallbackUrl::DEPOSIT_ATTEMPTS_EXCEEDED)
          .and_return(callback_url)

        allow(::Deposits::InitiateHostedDepositService)
          .to receive(:call).and_raise(Deposits::DepositAttemptError)

        wallet.currency.save!
      end

      it 'redirects to callback url when deposit attempts exceeded' do
        expect(
          get(
            :initiate,
            params: valid_params.update(token: valid_token)
          )
        ).to redirect_to(callback_url)
      end
    end

    %i[success error pending back].each do |state|
      context "When #{state} callback request made" do
        let(:callback_url) { Faker::Internet.url }
        let(:some_state) { Faker::Lorem.word }

        before do
          allow(SafeCharge::CallbackHandler)
            .to receive(:call) { some_state }
          allow(Deposits::CallbackUrl)
            .to receive(:for).with(some_state) { callback_url }
        end

        it "redirects #{state} to callback service state" do
          expect(get(state)).to redirect_to(callback_url)
        end
      end
    end

    context 'when unsupported currency received' do
      let(:expected_message) do
        'Deposit request with corrupted data received. ' \
        'Currency with code INVALID not found.'
      end

      before do
        allow(Rails.logger).to receive(:error)
        get(
          :initiate,
          params: valid_params
                    .update(currency_code: 'INVALID',
                            token: JwtService.encode(id: customer.id))
        )
      end

      it 'notifies about an error' do
        expect(Rails.logger)
          .to have_received(:error)
          .with(expected_message)
          .once
      end
    end
  end

  describe '#webhook' do
    context 'success' do
      before do
        allow(Rails.logger).to receive(:fatal)
        allow(SafeCharge::WebhookHandler).to receive(:call)

        get(:webhook)
      end

      it 'responds with ok' do
        expect(response).to have_http_status(:ok)
      end

      it 'does not log anything' do
        expect(Rails.logger).not_to have_received(:fatal)
      end
    end

    context 'error' do
      let(:error) do
        ActiveRecord::RecordNotFound.new(Faker::Superhero.name)
      end

      before do
        allow(Rails.logger).to receive(:fatal)
        allow(SafeCharge::WebhookHandler)
          .to receive(:call)
          .and_raise(error)

        get(:webhook)
      end

      it 'responds with internal server error' do
        expect(response).to have_http_status(:internal_server_error)
      end

      it 'notifies about an error' do
        expect(Rails.logger).to have_received(:fatal).with(error.message)
      end
    end
  end
end
