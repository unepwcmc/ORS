$(document).ready(function() {
  $(document).on('change', '.question-answered-box', function(){
    the_id = $(this).data('the-id')
    text_answer_field = $(this).closest('.text-answer').find('.text-answer-field')
    if($(this).prop('checked')) {
      $(text_answer_field).attr("readonly", true)
      $(text_answer_field).addClass("disabled")
      $("input[name='answers["+the_id+"]']:radio").attr("disabled", true)
      $("li.answer-option-"+the_id+" textarea").attr("disabled", true)
      $("select#answers_"+the_id).attr("disabled", true)
    }
    else {
      $(text_answer_field).attr("disabled", false)
      $(text_answer_field).attr("readonly", false)
      $(text_answer_field).removeClass("disabled")
      $("input[name='answers["+the_id+"]']:radio").attr("disabled", false)
      $("li.answer-option-"+the_id+" textarea").attr("disabled", false)
      $("select#answers_"+the_id).attr("disabled", false)
      $('.sticky_save_all').click();
    }
  });
});
