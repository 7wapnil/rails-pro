# frozen_string_literal: true

shared_context 'events for specific date' do
  let(:events_payload) do
    XmlParser.parse(file_fixture('events_for_specific_date.xml').read)
  end

  competitor_ids = (1..4)

  competitor_ids.each do |id|
    let(:"competitor_#{id}_payload") do
      XmlParser.parse(
        file_fixture("events_for_specific_date/sr-competitor-#{id}.xml").read
      )
    end
  end

  before do
    allow_any_instance_of(OddsFeed::Radar::ResponseReader)
      .to receive(:call)
      .and_call_original

    allow(OddsFeed::Radar::ResponseReader)
      .to receive(:call)
      .with(
        hash_including(
          path: "/sports/en/schedules/#{mocked_date}/schedule.xml",
          method: :get
        )
      )
      .and_return(events_payload)

    competitor_ids.each do |id|
      allow(OddsFeed::Radar::ResponseReader)
        .to receive(:call)
        .with(
          hash_including(
            path: "/sports/en/competitors/sr:competitor:#{id}/profile.xml",
            method: :get
          )
        )
        .and_return(send("competitor_#{id}_payload"))
    end
  end
end
