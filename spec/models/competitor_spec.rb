describe Competitor do
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:external_id) }

  it { is_expected.to have_many(:players) }

  it 'tests me' do
    sql = <<~SQL
      DELETE FROM competitor_players a USING competitor_players b
      WHERE
          a.competitor_id < b.competitor_id
          AND a.player_id = b.player_id
    SQL

    Competitor::Base.connection.execute(sql)
  end
end
