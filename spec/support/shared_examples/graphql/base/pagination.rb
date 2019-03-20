# frozen_string_literal: true

shared_examples_for Base::Pagination do
  let(:pagination_info_query) do
    %(
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
    )
  end

  let(:full_query) do
    pagination_query
      .split('{')
      .tap { |parts| add_pagination!(parts) }
      .join('{')
  end

  let(:result) do
    ArcanebetSchema.execute(full_query,
                            context: pagination_context,
                            variables: pagination_variables)
  end

  let(:query_name) do
    pagination_query
      .split('{')[1]
      .gsub(/\(.*\)/, '')
      .strip
  end

  let(:query_class) { ArcanebetSchema.query.fields[query_name].function.class }

  let(:response) { result['data'][query_name] }
  let(:response_pagination_info) do
    response['pagination']
      .symbolize_keys
      .slice(*Base::Pagination::Info.members)
  end

  let(:pagination) do
    Base::Pagination::Info.new(*response_pagination_info.values)
  end

  let(:response_collection_ids) do
    response['collection'].map { |item| item['id'].to_i }
  end

  let(:limited_collection_ids) do
    paginated_collection
      .take(Base::Pagination::DEFAULT_ITEMS_COUNT)
      .map(&:id)
  end

  before do
    stub_const('Base::Pagination::DEFAULT_ITEMS_COUNT', 1)
    stub_const('Base::Pagination::FIRST_PAGE', 1)

    allow(query_class.arguments['page'])
      .to receive(:default_value)
      .and_return(Base::Pagination::DEFAULT_ITEMS_COUNT)
    allow(query_class.arguments['per_page'])
      .to receive(:default_value)
      .and_return(Base::Pagination::FIRST_PAGE)

    paginated_collection
  end

  def add_pagination!(parts)
    return if parts[2].blank? || parts[2].include?('pagination')

    parts[2] = "#{pagination_info_query}#{parts[2]}"
  end

  def append_arguments!(part, query_name, page, per_page)
    if part.match?(/^\s*#{query_name}\s*\(/)
      return part.gsub!(/\)\s*$/, ", page: #{page}, per_page: #{per_page})")
    end

    part.gsub!(query_name,
               "#{query_name} (page: #{page}, per_page: #{per_page})")
  end

  it 'returns collection as data' do
    expect(response_collection_ids).to eq(limited_collection_ids)
  end

  it 'returns default pagination data' do
    expect(pagination).to have_attributes(
      count: paginated_collection.size,
      items: Base::Pagination::DEFAULT_ITEMS_COUNT,
      page: Base::Pagination::FIRST_PAGE
    )
  end

  context 'with explicitly set pagination arguments' do
    let(:page) { paginated_collection.size }
    let(:per_page) { 1 }
    let(:full_query) do
      pagination_query
        .split('{')
        .tap { |parts| append_arguments!(parts[1], query_name, page, per_page) }
        .tap { |parts| add_pagination!(parts) }
        .join('{')
    end

    it 'returns respective pagination data' do
      expect(pagination).to have_attributes(
        count: paginated_collection.size,
        items: per_page,
        page: page
      )
    end

    context 'on incorrect page' do
      let(:page) { paginated_collection.size + 1 }
      let(:error_message) do
        "expected :page in 1..#{paginated_collection.size}; got #{page}"
      end

      it 'returns an error' do
        expect(result['errors'].first['message']).to eq(error_message)
      end
    end
  end
end
