describe Radar::EventScopesLoadingWorker do
  it 'calls EventScopesCreatingWorker with received payload' do
    tournaments_response =
      XmlParser.parse(file_fixture('tournaments_response.xml').read)

    allow(subject).to receive(:api_client) do
      OpenStruct.new(tournaments: tournaments_response)
    end

    expect(Radar::EventScopesCreatingWorker)
      .to receive(:perform_async)
      .once
      .ordered
      .with(tournaments_response['tournaments']['tournament'][0])

    expect(Radar::EventScopesCreatingWorker)
      .to receive(:perform_async)
      .once
      .ordered
      .with(tournaments_response['tournaments']['tournament'][1])

    subject.perform
  end
end
