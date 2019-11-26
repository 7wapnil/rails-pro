# frozen_string_literal: true

describe Customers::UpdateForm, type: :model do
  subject(:form) { described_class.new(subject: customer, **params) }

  let(:customer) { create(:customer, address: build(:address)) }
  let(:params) { default_params }
  let(:default_params) do
    {
      first_name: 'test',
      last_name: 'test1',
      city: 'London',
      street_address: 'Baker st',
      phone: '+12065550100'
    }
  end

  context 'presence' do
    it { is_expected.to validate_presence_of(:subject) }
    it { is_expected.to validate_presence_of(:first_name) }
    it { is_expected.to validate_presence_of(:last_name) }
    it { is_expected.to validate_presence_of(:city) }
    it { is_expected.to validate_presence_of(:street_address) }
    it { is_expected.to validate_presence_of(:phone) }
  end

  describe '#submit!' do
    context 'when valid' do
      before { form.submit! }

      it 'updates customer' do
        expect(customer.reload).to have_attributes(
          phone: params[:phone].delete('+'),
          **params.slice(:first_name, :last_name)
        )
      end

      it 'updates address' do
        expect(customer.reload.address).to have_attributes(
          params.slice(:street_address, :city)
        )
      end
    end

    context 'with invalid phone' do
      let(:params) { default_params.merge(phone: '+9999999999999') }

      it 'raises an error' do
        expect { form.submit! }.to raise_error(ActiveModel::ValidationError)
      end
    end
  end
end
