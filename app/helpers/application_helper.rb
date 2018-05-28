module ApplicationHelper
  def card(header: nil)
    content_tag(:div, class: 'card') do
      concat content_tag(:h5, class: 'card-header') { header } if header
      concat content_tag(:div, class: 'card-body') { yield }
    end
  end
end
