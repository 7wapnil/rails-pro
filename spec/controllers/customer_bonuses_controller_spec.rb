# frozen_string_literal: true

describe CustomerBonusesController, type: :controller do
  describe '#create' do
    let!(:primary_currency) { create(:currency, :primary) }
    let!(:wallet) { create(:wallet) }
    let!(:original_bonus) { create(:bonus) }
    let(:amount) { rand(1..1000).to_s }
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

    before do
      allow(CustomerBonuses::Create)
        .to receive(:call)
        .and_return(customer_bonus)

      sign_in current_user
    end

    context 'on success' do
      before { create_bonus }

      it 'calls CustomerBonuses::Create with wallet and bonus' do
        expect(CustomerBonuses::Create)
          .to have_received(:call)
          .with(wallet: wallet,
                bonus: original_bonus,
                amount: amount)
      end

      it 'redirects to customer bonuses page' do
        expect(create_bonus)
          .to redirect_to(bonuses_customer_path(customer_bonus.customer))
      end

      it 'sets success message' do
        expect(controller)
          .to set_flash[:notice].to(
            I18n.t(:activated, instance: I18n.t('entities.bonus'))
          )
      end
    end

    context 'on failure' do
      let(:error_message) { Faker::WorldOfWarcraft.quote }

      before do
        allow(CustomerBonuses::Create)
          .to receive(:call)
          .and_raise(CustomerBonuses::ActivationError, error_message)
        create_bonus
      end

      it 'redirects to customer bonuses page' do
        expect(create_bonus)
          .to redirect_to(bonuses_customer_path(wallet.customer))
      end

      it 'sets error message' do
        expect(controller).to set_flash[:alert].to(error_message)
      end
    end
  end
end
