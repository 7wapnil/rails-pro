describe Redirection::DepositsController do
  describe '#initiate' do
    subject do
      get :initiate,
          params: { token: JwtService.encode(id: customer.id),
                    currency_code: wallet.currency.code,
                    amount: 50,
                    bonus_code: bonus.code }
    end

    let(:bonus) { build(:bonus) }
    let(:wallet) { build(:wallet) }
    let(:customer) { wallet.customer }
    let(:gateway_url) { Faker::Internet.url }
    let(:frontend_url) { Faker::Internet.url }

    before do
      allow(ENV).to receive(:[])
        .with('SAFECHARGE_HOSTED_PAYMENTS_URL')
        .and_return(gateway_url)
      allow(ENV).to receive(:[])
        .with('FRONTEND_URL')
        .and_return(frontend_url)
      allow(Deposits::InitiateHostedDepositService)
        .to receive(:call) {
          create(:entry_request, status: EntryRequest::INITIAL)
        }
    end

    it 'redirects_to gateway URL with params' do
      expect(subject).to redirect_to(gateway_url)
    end

    context 'with failure detected' do
      let(:failed_request) do
        create(:entry_request,
               status: EntryRequest::FAILED,
               result: Faker::Lorem.sentence(5))
      end
      let(:failure_url) do
        frontend_url +
          '?id=' + failed_request.id.to_s +
          '&reason=' + CGI.escape(failed_request.result) +
          '&success=false'
      end

      before do
        allow(Deposits::InitiateHostedDepositService)
          .to receive(:call) { failed_request }
      end

      it 'redirects back to frontend' do
        expect(subject).to redirect_to(failure_url)
      end
    end
  end
end
