function reloadPlayItems(el) {
  const XHR_URL = '/every_matrix/vendor_play_items/'
  const vendorId = el.value
  const xhr = new XMLHttpRequest();
  xhr.onreadystatechange = function() {
    if (xhr.readyState === 4) {
      document.getElementById('play-items').innerHTML = xhr.responseText;
    }
  };
  xhr.open('GET', XHR_URL + vendorId);
  xhr.send();
}

reloadPlayItems(document.getElementById('every_matrix_free_spin_bonus_every_matrix_vendor_id'))
