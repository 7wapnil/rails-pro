module ApplicationHelper
  def card(opts = {})
    header = opts[:header]
    css_class = ['card', opts[:class]].join(' ')

    content_tag(:div, class: css_class) do
      concat content_tag(:h5, class: 'card-header') { header } if header
      concat content_tag(:div, class: 'card-body') { yield }
    end
  end

  def link_back
    link_to t(:back), :back, class: 'btn btn-outline-dark'
  end

  def visibility_badge(visible, id)
    badge_style = "badge badge-#{visible ? 'success' : 'danger'}"
    badge_text = visible ? 'visible' : 'invisible'
    tag.span(class: badge_style, id: "badge_#{id}") { badge_text }
  end

  def visibility_toggle(visible, badge_id, toggle_endpoint)
    tag.div(class: 'form-check') do
      concat check_box_tag('visible', visible, visible,
                           id: nil,
                           class: 'form-check-input visibility_toggle',
                           data: { endpoint: toggle_endpoint,
                                   badge: "badge_#{badge_id}" })
      concat label_tag('Visible', nil, class: 'form-check-label')
    end
  end
end
