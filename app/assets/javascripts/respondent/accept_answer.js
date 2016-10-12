$(document).ready(function() {
  $(document).on('click', '.accept-btn', function(e) {
    e.preventDefault();
    answer = $(this).closest('.delegate-text-answer').find('textarea').val();
    answer_wrapper = $(this).closest('.answer_fields_wrapper')
    text_answer = $(answer_wrapper).find('.text-answer')
    text_answer_field = $(text_answer).find('.text-answer-field')
    question_answered = $(answer_wrapper).find('.answer-details').
      find('.question-answered-box').prop('checked')
    if(!question_answered) {
      $(text_answer_field).val(answer);
      $(text_answer_field).addClass('dirty');
    }
  });
});
