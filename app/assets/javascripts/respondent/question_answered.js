$(document).ready(function() {
  $(document).on('change', '.question-answered-box', function(){
    text_answer_field = $(this).closest('.text-answer').find('.text-answer-field')
    if($(this).prop('checked')) {
      $(text_answer_field).attr("readonly", true)
      $(text_answer_field).addClass("disabled")
    }
    else {
      $(text_answer_field).attr("disabled", false)
      $(text_answer_field).attr("readonly", false)
      $(text_answer_field).removeClass("disabled")
      $('.sticky_save_all').click();
    }
  });
});
