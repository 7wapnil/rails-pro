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

  private

  def render_radio_label_pair(opts = {})
    tag.div(class: 'form-check form-check-inline') do
      concat render_radio_tag(opts)
      concat render_radio_label_tag(opts)
    end
  end

  def render_radio_tag(opts = {})
    radio_button_tag(
      opts[:attribute_name],
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
