$(document).ready(function() {
  $(document).on('click', '.fake-file-input', function(e) {
    e.preventDefault();
    $(this).closest('li').find('.real-file-input').click();
  });

  $(document).on('change', '.real-file-input', function(e) {
    var filename = $(this).val().split(/\\/).pop();
    $(this).closest('li').find('.file-input-text').html(filename);
  });
});
