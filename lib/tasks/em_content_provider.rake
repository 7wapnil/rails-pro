namespace :em_content_provider do
  desc 'Filling internal image name'
  UPDATE_TABLES = %w[every_matrix_vendors every_matrix_content_providers].freeze

  task fill_in_internal_images: :environment do
    UPDATE_TABLES.each do |table|
      execute_query(table)
    end
  end

  def execute_query(table)
    ActiveRecord::Base.connection.execute(
      "UPDATE #{table} SET internal_image_name = slug"
    )
  end
end
