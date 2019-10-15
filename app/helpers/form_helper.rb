module FormHelper
  def build_enum_radio_group(opts = {})
    tag.div(class: 'form-group') do
      opts[:collection].map do |item|
        item_id = [
          opts[:resource].class.name.underscore.to_sym,
          opts[:attribute_name],
          item.first
        ].join('_')
        concat render_radio_label_pair(opts.merge(item: item, item_id: item_id))
      end
    end
  end

  def labels_selector(labelable, labels, element_id = nil)
    element_id ||= "#{labelable.class.to_s.downcase}_#{labelable.id}"
    update_url = polymorphic_url([:update_labels, labelable])
    placeholder = "Add #{labelable.class.to_s.downcase} label"

    collection_select(:labels, :ids, labels, :id, :name,
                      { selected: labelable.labels.ids },
                      class: 'form-control labels_selector',
                      id: element_id,
                      multiple: true,
                      data: { placeholder: placeholder,
                              update_url: update_url })
  end

  def simple_labels_selector(labelable, labels, element_id = nil)
    element_id ||= "#{labelable.class.to_s.downcase}_#{labelable.id}"
    placeholder = "Add #{labelable.class.to_s.downcase} label"
    collection_select(:labels, :ids, labels, :id, :name,
                      { selected: labelable.labels.ids },
                      class: 'form-control simple_labels_selector',
                      id: element_id,
                      multiple: true,
                      data: { placeholder: placeholder })
  end

  def content_for_days_range(resource)
    named_ranges = resource.class::NAMED_RANGES
    return named_ranges if !resource.range || named_ranges.key?(resource.range)

    { resource.range => I18n.t('days', days: resource.range) }
      .merge(named_ranges)
      .sort
      .to_h
  end

  private

  def render_radio_label_pair(opts = {})
    tag.div(class: 'form-check form-check-inline') do
      concat render_radio_tag(opts)
      concat render_radio_label_tag(opts)
    end
  end

  def render_radio_tag(opts = {})
    resource_name = opts[:resource].class.name.underscore.downcase
    input_name = "#{resource_name}[#{opts[:attribute_name]}]"
    radio_button_tag(
      input_name,
      opts[:item].first,
      opts[:resource].send(opts[:attribute_name]) == opts[:item].first,
      id: opts[:item_id],
      class: 'form-check-input'
    )
  end

  def render_radio_label_tag(opts = {})
    label_tag(
      t("#{opts[:translation_key]}.#{opts[:item].first}"),
      nil,
      for: opts[:item_id],
      class: 'form-check-label'
    )
  end
end
