describe GraphQL, '#withdrawals' do
  let(:context) { { current_customer: customer } }
  let(:variables) { {} }
  let(:customer) { create(:customer) }
  let(:query) do
    %({
          withdrawals(customerId: #{customer.id}) {
            id
          }
      })
  end
  let(:result) do
    ArcanebetSchema.execute(query, context: context, variables: variables)
  end

  let(:response_withdrawals) do
    result['data']['withdrawals']
  end

  context 'basic query usage' do
    let!(:customer_withdraws) do
      create_list(:entry_request, 2, :withdraw, customer: customer)
    end

    before do
      create_list(:entry_request, 2, :deposit, customer: customer)
    end

    it 'returns user withdrawals' do
      response_ids = response_withdrawals.map { |withdraw| withdraw['id'].to_i }

      expect(response_ids).to match_array(customer_withdraws.map(&:id))
    end
  end

  context 'pagination' do
    let(:max_per_page) do
      EntryRequest.max_per_page || EntryRequest.default_per_page
    end

    before do
      create_list(:entry_request,
                  max_per_page + 5,
                  :withdraw,
                  customer: customer)
    end

    it 'returns withdrawals for one page' do
      expect(response_withdrawals.length).to eq(max_per_page)
    end

    it 'allows to set count of withdraws per page' do
      per_page = 3
      query =  %({
          withdrawals(customerId: #{customer.id}, perPage: #{per_page}) {
            id
          }
      })

      result = ArcanebetSchema.execute(query,
                                       context: context,
                                       variables: variables)

      expect(result['data']['withdrawals'].length).to eq(per_page)
    end

    it 'accepts page number as argument' do
      records_on_last_page = 1
      per_page = EntryRequest.count - records_on_last_page

      query =  %({
          withdrawals(customerId: #{customer.id}, perPage: #{per_page},
                      page: 2) {
            id
          }
      })

      result = ArcanebetSchema.execute(query,
                                       context: context,
                                       variables: variables)

      expect(result['data']['withdrawals'].length).to eq(records_on_last_page)
    end
  end
end
