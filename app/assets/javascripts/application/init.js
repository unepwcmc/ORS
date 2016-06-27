$(document).ready(function() {
  $('input, textarea').placeholder();

  // All non-GET requests will add the authenticity token
  $(document).ajaxSend(function(event, request, settings) {
  if (typeof(window.AUTH_TOKEN) == "undefined") return;
    // IE6 fix for http://dev.jquery.com/ticket/3155
    if (settings.type == 'GET' || settings.type == 'get') return;

    settings.data = settings.data || "";
    settings.data += (settings.data ? "&" : "") + "authenticity_token=" + encodeURIComponent(window.AUTH_TOKEN);
  });
  treeAndSpinnerControls();
  initializeToolTips();
  hideFlashMessages();
  jQuery("#bread_crumb").jBreadCrumb({easing: 'linear'});
  ajaxLinks();
  $('ul.sf-menu').superfish();
  if($("#toggle_help").length > 0){
    $("#toggle_help").click(function(e){
      e.preventDefault();
      $("#help_div").toggle('slow');
    });
  }
});

var myLib =
{
  questionnaire_index :
  {
    init : function()
    {
      initialiseQuestionnairesIndexPage();
    }
  },
  questionnaire_new :
  {
    init : function()
    {
      initialiseQuestionnaireNewPage();
      formValidation();
    }
  },
  questionnaire_show :
  {
    init : function()
    {
      //Functions/Handlers necessary for the questionnaire_path(:id)
      initialiseShowQuestionnairePage();
    }
  },
  questionnaire_submission :
  {
    init : function()
    {
      //initialiseQuestionnaireSubmissionPage();
      handleInfoDisplayGeneratorShowPages();
      initialiseExtraFieldsHandlers();
      initialiseAuthorizedSubmittersPage();
    }
  },
  questionnaire_edit :
  {
    init : function()
    {
      initialiseQuestionnaireEditPage();
    }
  },
  questionnaire_authorized_submitters :
  {
    init : function()
    {
      //Functions/Handlers necessary for the questionnaire_authorized_submitters_path()
      initialiseAuthorizedSubmittersPage();
      formValidation();
    }
  },
  generator_side_generic :
  {
    init : function()
    {
      handleInfoDisplayGeneratorShowPages();
      initialiseNewQuestionPage();
      initialiseExtraFieldsHandlers();
      initialiseHideDisplayLangFields();
      selectOtherField();
      formValidation();
      initializeDescriptionExtraFieldsHandlers();
    }
  },
  users_index :
  {
    init : function()
    {
      initialiseUsersIndexPage();
      initialiseAuthorizedSubmittersPage();
      formValidation();
    }
  },
  text_areas :
  {
    init : function()
    {
      startTinyMCE();
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
