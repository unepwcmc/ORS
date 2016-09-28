$(document).ready(function() {
  $(document).on('click', '.accept-btn', function(e) {
    e.preventDefault();
    answer = $(this).closest('.delegate-text-answer').find('textarea').val();
    text_answer = $(this).closest('.answer_fields_wrapper').find('.text-answer')
    $(text_answer).find('textarea').val(answer);
  });
});
