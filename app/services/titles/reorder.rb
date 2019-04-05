module Titles
  class Reorder < ApplicationService
    def initialize(sorted_titles)
      @sorted_titles = sorted_titles
    end

    def call
      Title.transaction do
        @sorted_titles.each_pair { |kind, ids| update_titles_order(kind, ids) }
      end
    end

    private

    def update_titles_order(kind, ids)
      ids.each_with_index do |id, position|
        Title.where(id: id).update_all(kind: kind, position: position)
      end
    end
  end
end
