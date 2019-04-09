/* eslint no-use-before-define: ["error", { "functions": false  }] */
/* eslint prefer-template: "warn" */

import $ from 'jquery';
import Sortable from 'sortablejs';

const template = require('./list.hbs');

function collectSortedArray(element) {
  const sortedArray = [];
  $('li', element).each((_1, tr) => {
    sortedArray.push($(tr).data('id'));
  });
  return sortedArray;
}

function updateSorting() {
  $('#overlay').show();
  $.ajax({
    type: 'POST',
    headers: {
      'X-CSRF-Token': document.querySelector('meta[name=csrf-token]').content
    },
    data: { sorted_event_scopes: collectSortedArray(this.el) },
    error: () => {
      $('#overlay').hide();
      alert('Something went wrong with the AJAX request');
    },
    success: () => {
      $('#overlay').hide();
    }
  });
}

function initSortable() {
  $('.sortable').each((_, element) => {
    Sortable.create(element, {
      onUpdate: updateSorting,
      onAdd: updateSorting
    });
  });
}

function attachExpander() {
  $('.expand-event-scope').off('click');
  $('.expand-event-scope').click(expandHandler);
}

function expandHandler(event) {
  event.preventDefault();
  $(this).closest('.event-scope-td').nextAll().remove();
  $(this).closest('li').siblings().removeClass('active');
  $(this).closest('li').addClass('active');
  initEventScopes($(this).data('id'));
}

function initEventScopes(eventScopeId) {
  const baseElement = $('#event-scopes-tr');
  $('#overlay').show();
  $.ajax({
    type: 'GET',
    url: '/event_scopes/get',
    headers: {
      'X-CSRF-Token': document.querySelector('meta[name=csrf-token]').content
    },
    data: {
      title_id: baseElement.data('title-id'),
      event_scope_id: eventScopeId
    },
    error: () => {
      $('#overlay').hide();
      alert('Something went wrong with the AJAX request');
    },
    success: (data) => {
      $('#overlay').hide();
      const html = template({ event_scopes: data.event_scopes });
      baseElement.append(html);
      attachExpander();
      initSortable();
    }
  })
}

$(() => {
  initEventScopes();
});
