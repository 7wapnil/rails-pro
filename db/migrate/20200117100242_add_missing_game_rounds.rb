class AddMissingGameRounds < ActiveRecord::Migration[5.2]
  def up
    execute <<~SQL
      INSERT INTO
        every_matrix_game_rounds (external_id, status, created_at, updated_at)
      SELECT
        t.round_id, 'expired', now(), now()
      FROM
        (SELECT DISTINCT round_id AS round_id FROM every_matrix_transactions) t
      WHERE
        t.round_id NOT IN (SELECT external_id FROM every_matrix_game_rounds)
    SQL
  end

  def down
    execute <<~SQL
      DELETE FROM every_matrix_game_rounds
    SQL
  end
end
