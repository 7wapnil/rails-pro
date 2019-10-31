# frozen_string_literal: true

describe GraphQL, '#bets' do
  let!(:auth_customer) { create(:customer) }
  let(:context) { { current_customer: auth_customer } }
  let(:result) do
    ArcanebetSchema.execute(query, context: context, variables: variables)
  end

  let!(:bets) { create_list(:bet, 5, customer: auth_customer) }
  let(:bet) { bets.sort_by(&:created_at).reverse.first }
  let(:query) do
    %(query bets($excludedStatuses: [BetsStatusEnum],
                 $ids: [ID],
                 $perPage: Int!,
                 $page: Int!) {
      bets(excludedStatuses: $excludedStatuses,
           ids: $ids,
           perPage: $perPage,
           page: $page) {
        pagination {
          items
        }
        collection {
          id
          createdAt
        }
      }
    })
  end
  let(:variables) do
    { excludedStatuses: excludedStatuses, ids: ids, perPage: 10, page: 1 }
  end
  let(:excludedStatuses) { nil }
  let(:ids) { nil }

  it 'returns bets' do
    expect(result['data']['bets']['collection'].first['id']).to eq(bet.id.to_s)
  end

  it 'includes pagination param - items' do
    expect(result['data']['bets']['pagination']['items'])
      .to eq(bets.length)
  end

  context 'with excluded statuses' do
    let(:excludedStatuses) { [Bet::FAILED, Bet::REJECTED] }

    before do
      create(:bet, :failed, customer: auth_customer)
      create(:bet, :rejected, customer: auth_customer)
    end

    it 'does not return failed or rejected bets' do
      expect(result['data']['bets']['pagination']['items'])
        .to eq(bets.length)
    end
  end

  context 'with ids' do
    let(:ids) { [bets.first, bets.last].map { |bet| bet.id.to_s } }

    let(:result_bet_ids) do
      result['data']['bets']['collection'].map { |bet| bet['id'] }
    end

    it 'returns only requested bets' do
      expect(result_bet_ids).to include(*ids)
    end
  end

  context 'without excluded statuses' do
    before do
      create(:bet, :failed, customer: auth_customer)
      create(:bet, :rejected, customer: auth_customer)
    end

    it 'does not return failed or rejected bets' do
      expect(result['data']['bets']['pagination']['items'])
        .to eq(bets.length + 2)
    end
  end

  context 'pagination' do
    let(:query) do
      %(
      query bets($excludedStatuses: [BetsStatusEnum], $ids: [ID]) {
        bets(excludedStatuses: $excludedStatuses, ids: $ids) {
          pagination {
            count
            items
            page
            pages
            offset
            last
            next
            prev
            from
            to
          }
          collection {
            id
            createdAt
          }
        }
      }
    )
    end
    let(:variables) { {} }

    it_behaves_like Base::Pagination do
      let(:paginated_collection) { bets.sort_by(&:created_at).reverse }
      let(:pagination_query) { query }
      let(:pagination_variables) { variables }
      let(:pagination_context) { context }
    end
  end
end
