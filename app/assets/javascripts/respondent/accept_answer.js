$(document).ready(function() {
  $(document).on('click', '.accept-btn', function(e) {
    e.preventDefault();
    answer = $(this).closest('.delegate-text-answer').find('textarea').val();
    text_answer = $(this).closest('.answer_fields_wrapper').find('.text-answer')
    text_answer_field = $(text_answer).find('.text-answer-field')
    $(text_answer_field).val(answer);
    $(text_answer_field).addClass('dirty')
  });
});
