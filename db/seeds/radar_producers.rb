puts 'Seeding supported radar producers ...'

radar_producers = [
  { id: 1, code: :liveodds },
  { id: 3, code: :pre }
]

radar_producers.each do |producer_data|
  Radar::Producer.find_or_create_by!(code: producer_data[:code]) do |producer|
    producer.assign_attributes(
      id: producer_data[:id],
      code: producer_data[:code],
      state: Radar::Producer::HEALTHY,
      last_successful_subscribed_at: Time.zone.now
    )
  end
end
