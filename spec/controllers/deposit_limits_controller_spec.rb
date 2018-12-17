describe DepositLimitsController, type: :controller do
  let(:value) { 100 }
  let(:range) { 7 }
  let(:current_user) { create(:admin_user) }
  let!(:primary_currency) { create(:currency, :primary) }
  let!(:customer) { create(:customer) }
  let!(:payload_params) do
    {
      deposit_limit: {
        customer_id: customer.id,
        currency_id: primary_currency.id,
        range: range,
        value: value
      }
    }
  end

  describe '#create' do
    let(:create_deposit_limit) { post :create, params: payload_params }

    context 'when admin user creates deposit limit for customer' do
      before do
        sign_in current_user
        allow(AuditLog).to receive(:create!)
        create_deposit_limit
      end

      it 'calls AuditLog::create! with created deposit limit' do
        expect(AuditLog)
          .to have_received(:create!).with(
            event: :deposit_limit_created,
            user_id: current_user.id,
            customer_id: customer.id,
            context: {
              currency_code: primary_currency.code,
              range: DepositLimit::NAMED_RANGES[range],
              value: value
            }
          )
      end
    end

    it 'redirects to customer\'s deposit limit page' do
      sign_in current_user
      expect(create_deposit_limit)
        .to redirect_to(deposit_limit_customer_path(customer))
    end
  end

  describe '#update' do
    let!(:deposit_limit) do
      create(
        :deposit_limit,
        customer: customer,
        range: range * 10,
        value: value * 10
      )
    end
    let(:update_deposit_limit) do
      patch :update,
            params: payload_params.merge(id: deposit_limit.id)
    end

    context 'when admin user updates deposit limit for customer' do
      before do
        sign_in current_user
        allow(AuditLog).to receive(:create!)
        update_deposit_limit
      end

      it 'updates deposit limit' do
        update_deposit_limit = DepositLimit.find(deposit_limit.id)

        expect(update_deposit_limit.value).to eq(value)
        expect(update_deposit_limit.range).to eq(range)
        expect(update_deposit_limit.currency).to eq(primary_currency)
      end

      it 'calls AuditLog::create! with updated deposit limit' do
        expect(AuditLog)
          .to have_received(:create!).with(
            event: :deposit_limit_updated,
            user_id: current_user.id,
            customer_id: customer.id,
            context: {
              currency_code: primary_currency.code,
              range: DepositLimit::NAMED_RANGES[range],
              value: value
            }
          )
      end
    end

    it 'redirects to customer\'s deposit limit page' do
      sign_in current_user
      expect(update_deposit_limit)
        .to redirect_to(deposit_limit_customer_path(customer))
    end
  end

  describe '#delete' do
    let!(:deposit_limit) { create(:deposit_limit, customer: customer) }
    let(:delete_deposit_limit) do
      delete :destroy, params: { id: deposit_limit.id }
    end

    context 'when admin user deleted deposit limit for customer' do
      before do
        sign_in current_user
        allow(AuditLog).to receive(:create!)
        delete_deposit_limit
      end

      it 'deletes deposit limit' do
        deleted_deposit_limit = DepositLimit.where(id: deposit_limit.id)

        expect(deleted_deposit_limit).to be_empty
      end

      it 'calls AuditLog::create! with updated deposit limit' do
        expect(AuditLog)
          .to have_received(:create!).with(
            event: :deposit_limit_deleted,
            user_id: current_user.id,
            customer_id: customer.id,
            context: {}
          )
      end
    end

    it 'redirects to customer\'s deposit limit page' do
      sign_in current_user
      expect(delete_deposit_limit)
        .to redirect_to(deposit_limit_customer_path(customer))
    end
  end
end
