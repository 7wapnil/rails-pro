describe ArcanebetSchema do
  let(:result) do
    ArcanebetSchema.execute(
      query_string,
       context: {},
       variables: {}
    )
  end

  describe 'query' do
    before do
      title = create(:title)
      create_list(:event, 5, title: title)
    end

    let(:query_string) { %|{ events { id name } }| }

    it 'should return list of events' do
      expect(result["data"]["events"].count).to eq(5)
    end
  end

end
