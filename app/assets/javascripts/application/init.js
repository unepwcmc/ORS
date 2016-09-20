$(document).ready(function() {
  $('input, textarea').placeholder();

  // All non-GET requests will add the authenticity token
  $(document).ajaxSend(function(event, request, settings) {
    if (typeof(window.AUTH_TOKEN) == "undefined") {
      return;
    }

    // IE6 fix for http://dev.jquery.com/ticket/3155
    if (settings.type == 'GET' || settings.type == 'get') {
      return;
    }

    settings.data = settings.data || "";
    settings.data += (settings.data ? "&" : "") + "authenticity_token=" + encodeURIComponent(window.AUTH_TOKEN);
  });

  treeAndSpinnerControls();
  initializeToolTips();
  hideFlashMessages();
  authorizationFunctionsHandlers();
  initialiseSelectAll();
  initialiseAuthorizedFilter();
  $("#bread_crumb").jBreadCrumb({easing: 'linear'});
  ajaxLinks();
  $('ul.sf-menu').superfish();

  var toggleHelp = $('#toggle_help');
  if(toggleHelp.length > 0) {
    toggleHelp.click(function(e) {
      e.preventDefault();
      $("#help_div").toggle('slow');
    });
  }

});

var myLib = {
  questionnaire_submission: {
    init: function() {
      handleInfoDisplayGeneratorShowPages();
      initialiseExtraFieldsHandlers();
      initialiseAuthorizedSubmittersPage();
    }
  },
  questionnaire_edit: {
    init: function() { initialiseQuestionnaireEditPage(); }
  },
  questionnaire_authorized_submitters: {
    init: function() {
      //Functions/Handlers necessary for the questionnaire_authorized_submitters_path()
      initialiseAuthorizedSubmittersPage();
      FormValidator.initialize($('#generator_form'));
    }
  },
  generator_side_generic: {
    init: function() {
      handleInfoDisplayGeneratorShowPages();
      initialiseNewQuestionPage();
      initialiseExtraFieldsHandlers();
      initialiseHideDisplayLangFields();
      selectOtherField();
      FormValidator.initialize($('#generator_form'));
      initializeDescriptionExtraFieldsHandlers();
    }
  },
  users_index: {
    init: function() {
      initialiseUsersIndexPage();
      initialiseAuthorizedSubmittersPage();
      FormValidator.initialize($('#generator_form'));
    }
  },
  text_areas: {
    init: function() {
      startTinyMCE();

      $('textarea.grow').livequery(function() {
        $(this).autosize();
      });

      //TODO: need to check if this will work with wysiwyg plugin!
      $(":submit").livequery('click', function(e) {
        if($('textarea.tinymce').length > 0) {
          tinyMCE.triggerSave();
        }

        return true;
      });
    }
  }
};
