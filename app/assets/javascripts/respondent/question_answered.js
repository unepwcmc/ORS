$(document).ready(function() {
  $(document).on('change', '.question-answered-box', function(){
    the_id = $(this).data('the-id')
    text_answer_field = $(this).closest('.text-answer').find('.text-answer-field')
    matrix_answer_field = $(this).closest('.answer_fields_wrapper').find('.submission-matrix')
    if(!$(this).prop('checked')) {
      $(text_answer_field).attr("disabled", false)
      $(text_answer_field).attr("readonly", false)
      $(text_answer_field).removeClass("disabled")
      $("input[name='answers["+the_id+"]']:radio").attr("disabled", false)
      checkbox_radio_element = "li.answer-option-"+the_id;
      checkbox_radio_inputs = $(checkbox_radio_element + " input[type='checkbox'], " + checkbox_radio_element + " input[type='radio']" )
      // Enable text box only if option was checked
      $(checkbox_radio_inputs).each(function() {
        $(this).attr("disabled", false)
        if($(this).prop('checked')) {
          $(this).parent().find('textarea').attr("disabled", false)
        }
      });
      // Enable also 'Other' option with text area
      other_element = "li.answer-option-"+the_id+"-other";
      other_input = $(other_element + " input[type='checkbox'], " + other_element + " input[type='radio']")
      $(other_input).attr('disabled', false)
      // Enable 'Other' text box only if 'Other' option is checked
      // This is because the text box should only be available if the 'Other'
      // option is selected.
      if($(other_input).prop('checked')) {
        $("textarea.answer-option-"+the_id+"-other-text").attr('disabled', false)
      }
      $("select#answers_"+the_id).attr("disabled", false)
      $(matrix_answer_field).find('select').attr("disabled", false)
      $(matrix_answer_field).find('input').attr("disabled", false)
      $('.sticky_save_all').click();
    }
  });
});
