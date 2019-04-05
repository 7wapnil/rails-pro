class TitlesController < ApplicationController
  protect_from_forgery prepend: true

  def index
    @titles_hash = Titles::CollectHashByKind.call
  end

  def create
    Titles::Reorder.call(params[:sorted_titles])
  end
end
