$(document).ready(function() {

  // All non-GET requests will add the authenticity token
  $(document).ajaxSend(function(event, request, settings) {
    if (typeof(window.AUTH_TOKEN) == 'undefined') return;

    // IE6 fix for http://dev.jquery.com/ticket/3155
    if (settings.type == 'GET' || settings.type == 'get') return;

    settings.data = settings.data || '';
    settings.data += (settings.data ? '&' : '') + 'authenticity_token=' + encodeURIComponent(window.AUTH_TOKEN);
  });

  initializeToolTips();
  hideFlashMessages();
  ajaxLinks();
  ajaxRequestsUnderway();

  $('ul.sf-menu').superfish();

  if($('#toggle_help').length > 0) {
    $('#toggle_help').click(function(e) {
      e.preventDefault();
      $('#help_div').toggle('slow');
    });
  }

  $('.app-content').on('click', '#change_lang', function(e) {
    e.preventDefault();
    $('#language_selection').toggle('slow');
  });

});

function ajaxRequestsUnderway() {
  $("#requests_dialog").dialog({
    autoOpen:false,
    resizable:false,
    closeOnEscape: false,
    modal:true,
    //width: 200,
    minHeight: 90,
    height: 130,
    draggable: false
  });

  $('#requests_dialog').livequery('ajaxSend', function() {
    if($('div.no_dialog').length === 0) {
      console.log('open');
      $(this).dialog('open').prev('.ui-dialog-titlebar').hide();
    }
  }).livequery('ajaxComplete', function() {
    console.log('close');
    if($('div.no_dialog').length === 0) {
      $(this).dialog('close');
    }
  });
}

function initialiseQuestionnaireSubmissionPage() {
  $('#add_document').dialog({autoOpen:false, resizable:false, modal:true, draggable:false, width: 600,
    close: function() {
      $('#add_document').empty();
    }
  });

  $('#add_links').dialog({autoOpen:false, resizable:false, modal:true, draggable:false, width: 600,
    close: function() {
      $('#add_links').empty();
    }
  });

  $('#delegate_section').dialog({autoOpen:false, resizable:false, modal:true, draggable:false, width:600});

  $('#toggle_delegation_details').click(function(e){
    e.preventDefault();
    $('#delegation_details').toggle('slow');
  });
}

// TODO: change function name to camelCase
// Also, this could be a setInterval, but I'm not gonna change it because I'm scared
// of the consequences
function timed_save() {
  setTimeout(function() {
    var anySectionSubmissions = ($('form.sectionSubmission').length > 0),
        noneToRenderDivs      = ($('#to_render').length === 0),
        anyDirtyDivs          = ($('.dirty').length > 0),
        saveFromButtonIsZero  = ($('#save_from_button').val() === '0'),
        timedSaveIsZero       = ($('#timed_save').val() === '0'),
        autoSaveIsZero        = ($('#auto_save').val() === '0');

    if(anySectionSubmissions && noneToRenderDivs && anyDirtyDivs && saveFromButtonIsZero && timedSaveIsZero && autoSaveIsZero) {
      $('#timed_save').val('1');

      $('#questionnaire').addClass('no_dialog');
      var section_id = $('#section').val();
      saveDirtyAnswers();
    }

    timed_save();
  }, 30000);
}

function saveDirtyAnswers() {
  var vals = $('select.dirty, input.dirty, textarea.dirty').serialize();

  vals += '&'+$('.disabled_section_information').serialize();
  vals += '&section='+$('#active_section').val();
  vals += '&save_from_button='+$('#save_from_button').val();
  vals += '&timed_save='+$('#timed_save').val();
  vals += '&auto_save='+$('#auto_save').val();
  vals += '&respondent_id='+$('#questionnaire_submission').data('respondent_id')

  markQuestionsAsAnswered();

  $('input.dirty, textarea.dirty, select.dirty').removeClass('dirty');

  if(!$('#questionnaire').hasClass('no_dialog')) {
    $('#requests_dialog').dialog('open');
  }

  $.ajax({
    url: '/sections/save_answers',
    type: 'post',
    dataType: 'script',
    data: vals
  });
}

function markQuestionsAsAnswered() {
  $('.question-answered-box:checked').each(function() {
    the_id = $(this).data('the-id')
    text_answer_field = $(this).closest('.text-answer').find('.text-answer-field')
    matrix_answer_field = $(this).closest('.answer_fields_wrapper').find('.submission-matrix')
    $(text_answer_field).attr("readonly", true)
    $(text_answer_field).addClass("disabled")
    $("input[name='answers["+the_id+"]']:radio").attr("disabled", true)
    $("li.answer-option-"+the_id+" textarea").attr("disabled", true)
    $("li.answer-option-"+the_id+" input[type='checkbox']").attr("disabled", true)
    // Disable also 'Other' option with text area
    $("li.answer-option-"+the_id+"-other input[type='checkbox']").attr('disabled', true)
    $("textarea.answer-option-"+the_id+"-other-text").attr('disabled', true)
    $("select#answers_"+the_id).attr("disabled", true)
    $(matrix_answer_field).find('select').attr("disabled", true)
    $(matrix_answer_field).find('input').attr("disabled", true)
  });
}

// Event handlers to flag fields as changed, that can then be saved.
function dirtyFlagging() {
  $("input[type='text'], textarea").blur(function() {
    // If the following is false, don't flag as dirty
    // The problem still here is that if the text is written before the readio button is clicked,
    // it won't be marked as dirty and the text won't be passed in to the backend
    // This is fixed a few lines later in the change listener for radio buttons.
   is_radio_type = $(this).parent().parent().find("input[type='radio']")
   if((is_radio_type.length > 0 && $(is_radio_type).is(':checked')) || is_radio_type.length == 0) {
     $(this).addClass('dirty');
     disableSubmit();
   }
  });

  $("input[type='checkbox']").change(function() {
    var $el = $(this);

    details_text = $el.parent().find('textarea');

    if(!$el.is(':checked')){
      $el.trigger('deselect');
      $el.prev("input[type='hidden']").addClass('dirty');
      $el.removeClass('dirty');
    } else {
      $el.prev("input[type='hidden']").removeClass('dirty');
      if(details_text.length) {
        $(details_text).addClass('dirty');
        $(details_text).removeAttr('disabled');
      }
      $el.addClass('dirty');
    }

    disableSubmit();
  });

  $("input[type='radio']").change(function() {
    var $el = $(this);

    //this if is needed for the clear answers functionality to work
    if(!$el.is(':checked')){
      $el.trigger('deselect');
      $el.prev("input[type='hidden']").addClass('dirty');
      $el.removeClass('dirty');
    }
    else {
      //trigger a custom deselect event to remove dirty flag to other radio buttons and details text
      $('input[name="' + $(this).attr('name') + '"][type="radio"]').not($(this)).trigger('deselect');

      $el.prev("input[type='hidden']").removeClass('dirty');
      //add dirty flag also on details text box, if present
      details_text = $el.parent().find('textarea');
      if(details_text.length) {
        $(details_text).addClass('dirty');
        $(details_text).removeAttr('disabled');
      }
      $el.addClass('dirty');
    }

    disableSubmit();
  });

  $('input[type="radio"], input[type="checkbox"]').bind('deselect', function(){
    var $el = $(this);
    //Commented next line which was causing problems when selecting some radio without details text
    // $el.prev("input[type='hidden']").addClass('dirty');
    //remove dirty flag also on details text box, if present
    details_text = $el.parent().find('textarea');
    if(details_text.length) {
      $(details_text).removeClass('dirty');
      $(details_text).attr('disabled', 'disabled')
    }
    $el.removeClass('dirty');
  })

  $('select').change(function() {
    var $el = $(this);

    if($el.attr('type') === 'select-multiple') {
      if($el.attr('value') === '') {
        $el.prev("input[type='hidden']").addClass('dirty');
        $el.removeClass('dirty');
      } else {
        $el.prev("input[type='hidden']").removeClass('dirty');
        $el.addClass('dirty');
      }
    } else {
      $el.addClass('dirty');
    }

    disableSubmit();
  });

  //Numeric type validation
  $('.numeric_type').keydown(function(event) {
    var withoutModifiers   = (!event.shiftKey && !event.ctrlKey && !event.altKey),
        isNumKeys          = (event.keyCode >= 48 && event.keyCode <= 57),
        isNumpadKeys       = (event.keyCode >= 96 && event.keyCode <= 105);
        notEsc             = (event.keyCode !== 8),
        notDel             = (event.keyCode !== 46),
        notLeftOrRight     = (event.keyCode !== 37 && event.keyCode !== 39),
        notTab             = (event.keyCode !== 9);

    if (withoutModifiers && (isNumKeys || isNumpadKeys)) {
      // check textbox value now and tab over if necessary
      // Yes, this is empty...
    } else if(event.keyCode == 109) { // allow '-' if it's the first value in the text_field
      // if there's already a '-' sign, don't put any other
      if($(this).val().indexOf('-') !== -1) {
        event.preventDefault();
      } else {
        $(this).val('-'+$(this).val()); //wherever the user places the '-' sign, put it at the beginning of the text field
        event.preventDefault();
      }
    } else if(event.keyCode === 190) { // You can add only one '.'
      if($(this).val().indexOf('.') !== -1) {
        event.preventDefault();
      }
    } else if(event.keyCode == 188) { // You can add only one ','
      if($(this).val().indexOf(',') !== -1 ) {
        event.preventDefault();
      }
    } else if(notEsc && notDel && notLeftOrRight && notTab) { // not esc, del, left or right
      event.preventDefault();
    }
    // else the key should be handled normally

  }).blur(function(event) {
    var value = $(this).val(),
        min = $(this).attr('data-min'),
        max = $(this).attr('data-max');

    if(min !== undefined && parseInt(value) < parseInt(min)) {
      $(this).val('');
      $(this).focus();
      alert('Numeric value must be bigger than ' + min + '.');

    } else if(max !== undefined && parseInt(value) > parseInt(max)) {
      $(this).val('');
      alert('Numeric value must be smaller than ' + max + '.');
    }
  });
}

function disableSubmit() {
  $('#top_submission').hide();
  $('#top_submission_disabled').show();
}

// Functions that implement the behaviour of the RankedAnswerType UI.
function chooseOption(element, theId, maximumAllowed) {
  element.unbind('click');

  element.click(function(e) {
    e.preventDefault();
    var position = $('#choices_'+theId).find('li').size();

    if(maximumAllowed === -1 || position < maximumAllowed) {
      $(this).hide();

      $('#choices_'+theId).append($(this));
      $('#answers_'+theId+'_'+position).val($(this).attr('id').replace(theId +'_obj_', ''));
      $('#answers_'+theId+'_'+position).addClass('dirty');

      $(this).show();
      removeOption($(this), theId, maximumAllowed);
    }
  });
}

function removeOption(element, theId, maximumAllowed) {
  element.unbind('click');

  element.click(function(e) {
    e.preventDefault();
    $(this).hide();

    var position_removed = $(this).index();
    var total_elements = $('#choices_'+theId).find('li').size()-1;

    $('.'+theId +'_ranked_answers').each(function() {
      var position = parseInt($(this).attr('id').replace('answers_'+theId +'_', ''));

      if(position >= position_removed) {
        $('#answers_'+theId+'_'+position).addClass('dirty');

        if(position != total_elements) {
          $('#answers_'+theId+'_'+position).val($('#answers_'+theId+'_'+(position+1).toString()).val());
        } else {
          $('#answers_'+theId+'_'+position).val('');
        }
      }
    });

    $('#options_'+theId).append($(this));
    $(this).show();

    chooseOption($(this), theId, maximumAllowed);
  });
}

// TODO: camelCase this function name
function set_state_identifier(id, state, altText) {
  var icons = {
    newSection: "<i class='fa fa-asterisk background inverse info obj_tooltip' title='New Section'></i>",
    completeSection: "<i class='fa fa-check-circle background inverse success obj_tooltip' title='Section has been completed'></i>",
    someQuestionsUnanswered: "<i class='fa fa-plus-circle background inverse success obj_tooltip' title='Some questions unanswered'></i>",
    mandatoryQuestionsUnanswered: "<i class='fa fa-exclamation-triangle background inverse warning obj_tooltip' title='Some questions unanswered'></i>",
    allQuestionsUnanswered: "<i class='fa fa-times-circle background inverse info obj_tooltip' title='All questions unanswered'></i>",
    findIcon: function(n){
      switch(n) {
        case 0:
          return this.allQuestionsUnanswered;
          break;
        case 1:
          return this.mandatoryQuestionsUnanswered;
          break;
        case 2:
          return this.someQuestionsUnanswered;
          break;
        case 3:
          return this.completeSection;
          break;
        case 4:
          return this.newSection;
          break;
      }
    }
  };
  $("#img"+id).empty();
 // $("#img"+id).append("<img class='obj_tooltip' src='"+RAILS_ROOT+"/assets/submissionstate/fidelitybyagapeh/"+state+".png' alt='"+altText+"' title='"+altText+"' width='20px' height='20px'/>");
  $("#img"+id).append(icons.findIcon(parseInt(state)));
}

var myLib = {
  questionnaire_submission: {
    init: function() {
      initialiseQuestionnaireSubmissionPage();
      handleInfoDisplayGeneratorShowPages();
      initialiseExtraFieldsHandlers();
      //initialiseAuthorizedSubmittersPage();
    }
  },
  text_areas: {
    init: function() {
      //startTinyMCE();
      $('textarea.grow').livequery(function() {
        $(this).autosize();
      });

      //TODO: need to check if this will work with wysiwyg plugin!
      $(":submit").livequery('click', function(e) {
        if($('textarea.tinymce').length > 0) {
          tinyMCE.triggerSave();
        }

        return true;
      })
    }
  }
};
