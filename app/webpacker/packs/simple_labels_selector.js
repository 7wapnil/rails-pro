import 'select2/dist/css/select2.min.css'
import 'select2/dist/js/select2.full.min'

$(document).on('turbolinks:load', () => {
  $('.simple_labels_selector').select2({
    minimumInputLength: 0
  });
});
