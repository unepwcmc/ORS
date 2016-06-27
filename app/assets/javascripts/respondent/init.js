$(document).ready(function() {
  // All non-GET requests will add the authenticity token
  $(document).ajaxSend(function(event, request, settings) {
  if (typeof(window.AUTH_TOKEN) == "undefined") return;
    // IE6 fix for http://dev.jquery.com/ticket/3155
    if (settings.type == 'GET' || settings.type == 'get') return;

    settings.data = settings.data || "";
    settings.data += (settings.data ? "&" : "") + "authenticity_token=" + encodeURIComponent(window.AUTH_TOKEN);
  });
  initializeToolTips();
  hideFlashMessages();
  ajaxLinks();
  ajaxRequestsUnderway();
  $('ul.sf-menu').superfish();
  if($("#toggle_help").length > 0){
    $("#toggle_help").click(function(e){
      e.preventDefault();
      $("#help_div").toggle('slow');
    });
  }
});

function ajaxRequestsUnderway() {
  $("#requests_dialog").dialog({
    autoOpen:false,
    resizable:false,
    closeOnEscape: false,
    modal:true,
    width: 200,
    minHeight: 90,
    height: 130,
    draggable: false
  });
  $("#requests_dialog").livequery('ajaxSend', function() {
    if($("div.no_dialog").length === 0)
      $(this).dialog("open")
      .prev('.ui-dialog-titlebar') // Get title bar,...
        //.find('a')                   // ... then get the X close button ...
        .hide();                     // ... and hide it;
      })
  .livequery('ajaxSuccess', function() {
    if($("div.no_dialog").length === 0)
      $(this).dialog("close");
  });
}

function initialiseQuestionnaireSubmissionPage(){
  $("#add_document").dialog({autoOpen:false, resizable:false, modal:false, width: 600,
    close: function(){
      $("#add_document").empty();
    }
  });
  $("#add_links").dialog({ autoOpen:false, resizable:false, modal:false, width: 600,
    close: function(){
      $("#add_links").empty();
    }
  });
  $("#delegate_section").dialog({ autoOpen:false, resizable:false, modal:false, width:600});
  $("#toggle_delegation_details").click(function(e){
    e.preventDefault();
    $("#delegation_details").toggle('slow');
  });
}

function timed_save()
{
  setTimeout(function(){
    if($("form.sectionSubmission").length > 0 && $(".dirty").length > 0 && $("#to_render").length === 0 && $("#save_from_button").val() === "0" && $("#timed_save").val() === "0" && $("#auto_save").val() === "0")
    {
      $("#timed_save").val("1");
      $("#questionnaire").addClass("no_dialog");
        //$("form.sectionSubmission").submit();
        var section_id = $("#section").val();
        saveDirtyAnswers();
    }
    timed_save();
  }, 30000);
}

function saveDirtyAnswers(){
  var vals = $("select.dirty, input.dirty, textarea.dirty").serialize();
  vals += "&"+$(".disabled_section_information").serialize();
  vals += "&section="+$("#active_section").val()+"&save_from_button="+$("#save_from_button").val()+"&timed_save="+$("#timed_save").val()+"&auto_save="+$("#auto_save").val();
  $("input.dirty, textarea.dirty, select.dirty").removeClass('dirty');
  if(!$("#questionnaire").hasClass("no_dialog")){
    $("#requests_dialog").dialog("open");
  }
  $.ajax({url: "/sections/save_answers", type: "post", dataType: "script", data: vals });
}
//Event handlers to flag fields as changed, that can then be saved.
function dirtyFlagging(){
  $("input[type='text'], textarea").blur(function(){
   $(this).addClass("dirty");
   disableSubmit();
 });
  $("input[type='checkbox']").change(function(){
    if(!$(this).is(':checked')){
      $(this).prev("input[type='hidden']").addClass("dirty");
      $(this).removeClass("dirty");
    }else{
      $(this).prev("input[type='hidden']").removeClass("dirty");
      $(this).addClass("dirty");
    }
    disableSubmit();
  });
  $("input[type='radio']").change(function(){
    if(!$(this).is(':checked')){
      $(this).prev("input[type='hidden']").addClass("dirty");
      $(this).removeClass("dirty");
    }else{
      $(this).prev("input[type='hidden']").removeClass("dirty");
      $(this).addClass("dirty");
    }
    disableSubmit();
  });
  $("select").change(function(){
    if($(this).attr('type') === "select-multiple"){
      if($(this).attr("value") === ""){
        $(this).prev("input[type='hidden']").addClass("dirty");
        $(this).removeClass("dirty");
      }else{
        $(this).prev("input[type='hidden']").removeClass("dirty");
        $(this).addClass("dirty");
      }
    }else {
      $(this).addClass("dirty");
    }
    disableSubmit();
  });
  //Numeric type validation
  $(".numeric_type").keydown(function(event) {
      if ((!event.shiftKey && !event.ctrlKey && !event.altKey) && ((event.keyCode >= 48 && event.keyCode <= 57) || (event.keyCode >= 96 && event.keyCode <= 105))){ // 0-9 or numpad 0-9, disallow shift, ctrl, and alt
        // check textbox value now and tab over if necessary
      }else if(event.keyCode == 109){// allow '-' if it's the first value in the text_field
        if($(this).val().indexOf("-") !== -1){//if there's already a '-' sign, don't put any other
          event.preventDefault();
      }else{
          $(this).val("-"+$(this).val());//wherever the user places the '-' sign, put it in the begining of the text field.
          event.preventDefault();
        }
      }else if(event.keyCode === 190){//You can add a period
        if($(this).val().indexOf(".") !== -1){
          event.preventDefault();
        }
      } else if(event.keyCode == 188){//You can add a comma
        if($(this).val().indexOf(",") !== -1 ){
          event.preventDefault();
        }
      }else if (event.keyCode !== 8 && event.keyCode !== 46 && event.keyCode !== 37 && event.keyCode !== 39 && event.keyCode !== 9){ // not esc, del, left or right
        event.preventDefault();
      }
      // else the key should be handled normally
    }).blur(function(event){
      var value = $(this).val();
      var min = $(this).attr("data-min");
      var max = $(this).attr("data-max");
      if(min !== undefined && parseInt(value) < parseInt(min)){
        $(this).val("");
        $(this).focus();
        alert("Numeric value must be bigger than " + min + ".");
      }else if(max !== undefined && parseInt(value) > parseInt(max)){
        $(this).val("");
        alert("Numeric value must be smaller than " + max + ".");
      }
    });
  }

function disableSubmit(){
  $("#top_submission").hide();
  $("#top_submission_disabled").show();
}

//Functions that implement the behaviour of the RankedAnswerType UI.
function chooseOption(element, the_id, maximum_allowed)
{
  element.unbind('click');
  element.click(function(e){
    e.preventDefault();
    var position = $("#choices_"+the_id).find('li').size();
    if(maximum_allowed === -1 || position < maximum_allowed)
    {
      $(this).hide();
      $("#choices_"+the_id).append($(this));
      $("#answers_"+the_id+"_"+position).val($(this).attr("id").replace(the_id +"_obj_", ""));
      $("#answers_"+the_id+"_"+position).addClass('dirty');
      $(this).show();
      removeOption($(this), the_id, maximum_allowed);
    }
  })
}

function removeOption(element, the_id, maximum_allowed)
{
  element.unbind('click');
  element.click(function(e){
    e.preventDefault();
    $(this).hide();
    var position_removed = $(this).index();
    var total_elements = $("#choices_"+the_id).find('li').size()-1;
    $("."+the_id +"_ranked_answers").each(function(){
      var position = parseInt($(this).attr("id").replace("answers_"+the_id +"_", ""));
      if(position >= position_removed)
      {
        $("#answers_"+the_id+"_"+position).addClass('dirty');
        if(position != total_elements)
          $("#answers_"+the_id+"_"+position).val($("#answers_"+the_id+"_"+(position+1).toString()).val());
        else
          $("#answers_"+the_id+"_"+position).val("");
      }
    });
    $("#options_"+the_id).append($(this));
    $(this).show();
    chooseOption($(this), the_id, maximum_allowed);
  });
}

function set_state_identifier(id, state, alt_text){
  $("#img"+id).empty();
  $("#img"+id).append("<img class='obj_tooltip' src='"+RAILS_ROOT+"/assets/submissionstate/fidelitybyagapeh/"+state+".png' alt='"+alt_text+"' title='"+alt_text+"' width='20px' height='20px'/>");
}

var myLib =
{
  questionnaire_submission :
  {
    init : function()
    {
      initialiseQuestionnaireSubmissionPage();
      handleInfoDisplayGeneratorShowPages();
      initialiseExtraFieldsHandlers();
      //initialiseAuthorizedSubmittersPage();
    }
  },
  text_areas :
  {
    init : function()
    {
      //startTinyMCE();
      $('textarea.grow').livequery(function(){
        $(this).autosize();
      });
      //TODO: need to check if this will work with wysiwyg plugin!
      $(":submit").livequery('click', function(e){
        if($('textarea.tinymce').length > 0)
          tinyMCE.triggerSave();
        return true;
      })
    }
  }
};
