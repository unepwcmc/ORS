$(function() {
  $('#search_questionnaire').change(function() {
    $('#users_answers').html('');
    var questionnaire_id = $(this).val();
    if(questionnaire_id !== '') {
      $.get(RAILS_ROOT+'/questionnaires/'+questionnaire_id+'/sections', null, null, 'script');
    }
  });

  $('#search_section').change(function() {
    $('#users_answers').html('');
    var section_id = $(this).val();
    if(section_id !== '') {
      $.get(RAILS_ROOT+'/sections/'+section_id+'/questions', null, null, 'script');
    }
  });

  $('#search_question').change(function() {
    $('#users_answers').html('');
    var question_id = $(this).val();
    data = {};

    if($('#responses_loop_items ul li').length > 0) {
      data = {
        'looping_selection': getLoopingIdentifierFromForm()
      };
    }
    if(question_id !== '') {
      $.get(RAILS_ROOT+'/questions/'+question_id+'/answers', data, null, 'script');
    }
  });

  $('.loop_item_positions').livequery(function() {
    $(this).change(function() {
      if($('#search_question').val() !== '') {
        $('#search_question').change();
      }
    });
  });

});

function getLoopingIdentifierFromForm() {
  if($('.loop_item_positions').length == 0) {
    return null;
  }

  var looping_selection = new Array($('.loop_item_positions').length);

  for(var i=0; i < looping_selection.length; i++) {
    looping_selection[i] = $('#search_loop_item_positions_'+i).val();
  }

  return looping_selection.join('_');
}
