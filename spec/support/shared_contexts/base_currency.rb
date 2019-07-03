shared_context 'base_currency' do
  let!(:base_currency) { create :currency, code: ::Currency::PRIMARY_CODE }
end
