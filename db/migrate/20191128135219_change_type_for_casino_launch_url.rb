class ChangeTypeForCasinoLaunchUrl < ActiveRecord::Migration[5.2]
  def change
    change_column :every_matrix_game_details, :launch_game_in_html_5, :string

    change_column_default :every_matrix_game_details, :launch_game_in_html_5, ''
  end
end
