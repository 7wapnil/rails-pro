class TitlesController < ApplicationController
  protect_from_forgery prepend: true

  find :title, only: %i[edit update]

  def index
    @titles_hash = Titles::CollectHashByKind.call
  end

  def create
    Titles::Reorder.call(params[:sorted_titles])
  end

  def update
    @title.update(title_params)

    return redirect_to(titles_path) if @title.errors.empty?

    render 'edit'
  end

  private

  def title_params
    params
      .require(:title)
      .permit(:id,
              :name,
              :short_name,
              :external_id,
              :show_category_in_navigation,
              :kind)
  end
end
