class TitlesController < ApplicationController
  protect_from_forgery prepend: true

  find :title, only: %i[edit update], friendly: true, decorate: true

  def index
    @titles_hash = Titles::CollectHashByKind.call
  end

  def create
    Titles::Reorder.call(params[:sorted_titles])
  end

  def update
    @title.update(title_params)

    return render :edit if @title.errors.any?

    redirect_to titles_path
  end

  private

  def title_params
    params
      .require(:title)
      .permit(:id,
              :slug,
              :meta_title,
              :meta_description,
              :external_id,
              :show_category_in_navigation,
              :kind,
              Title.globalize_attribute_names)
  end
end
