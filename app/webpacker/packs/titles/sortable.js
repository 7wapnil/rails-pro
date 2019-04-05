import $ from 'jquery';
import Sortable from 'sortablejs';

function collectSortedArrays() {
  const sortedHash = {};
  $('.sortable').each((_0, element) => {
    const kind = $(element).data('kind');
    sortedHash[kind] = [];
    $('td', element).each((_1, td) => {
      sortedHash[kind].push($(td).data('id'));
    });
  });
  return sortedHash;
}

function updateSorting() {
  $('#overlay').show();
  $.ajax({
    type: 'POST',
    headers: {
      'X-CSRF-Token': document.querySelector('meta[name=csrf-token]').content
    },
    data: { sorted_titles: collectSortedArrays() },
    error: () => {
      $('#overlay').hide();
      alert('Something went wrong with the AJAX request');
    },
    success: () => {
      $('#overlay').hide();
    }
  });
}

$(() => {
  $('.sortable').each((_, element) => {
    Sortable.create(element, {
      group: 'titles',
      onUpdate: updateSorting,
      onAdd: updateSorting
    });
  });
});
