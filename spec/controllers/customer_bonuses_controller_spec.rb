describe CustomerBonusesController, type: :controller do
  describe '#create' do
    let!(:wallet) { create(:wallet) }
    let!(:original_bonus) { create(:bonus) }
    let(:amount) { 100 }
    let!(:payload_params) do
      {
        customer_bonus: {
          amount: amount,
          wallet_id: wallet.id,
          original_bonus_id: original_bonus.id
        }
      }
    end
    let(:create_bonus) { post :create, params: payload_params }
    let(:current_user) { create(:admin_user) }
    let(:customer_bonus) { create(:customer_bonus) }

    context 'when admin user adds bonus to customer' do
      before do
        sign_in current_user
        allow(Bonuses::ActivationService)
          .to receive(:call).and_return(customer_bonus)
        allow(customer_bonus).to receive(:add_funds)
        allow(AuditLog).to receive(:create!)
        create_bonus
      end

      it 'calls Bonuses::ActivationService with wallet and bonus' do
        expect(Bonuses::ActivationService)
          .to have_received(:call).with(wallet, original_bonus)
      end

      it 'calls CustomerBonus::add_funds with amount' do
        expect(customer_bonus)
          .to have_received(:add_funds).with(amount)
      end

      it 'calls AuditLog::create! with wallet and bonus' do
        expect(AuditLog)
          .to have_received(:create!).with(
            event: :bonus_activated,
            user_id: current_user.id,
            customer_id: wallet.customer_id,
            context: { code: customer_bonus.code }
          )
      end
    end

    it 'redirects to customer bonuses page' do
      sign_in current_user
      expect(create_bonus)
        .to redirect_to(bonuses_customer_path(wallet.customer_id))
    end
  end
end
