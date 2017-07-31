/*
 * When an option like "Add Section" or "Add Question"
 * is clicked the info of the questionnaire/section/question is
 * collapsed to save space
 */
function collapseInfoGeneratorShowPages() {
  $('.info').each(function() {
    var $el = $(this);

    $el.slideUp('2000', function() {
      $el.prev('div').css('border-bottom-width', '1px');
    });
  });

  $('.show_info').each(function() {
    $(this).show().siblings('.hide_info').hide();
  });
}

function setupSyncTitle($tinymceEl) {
  var useTabTitleOption = $tinymceEl.parents().find('.use-tab-title'),
      tabTitle = $tinymceEl.parents().find('.tab-title'),
      isDescription = $tinymceEl.parent().hasClass('description-area'),
      tabTitleText;

  if(isDescription) { return };

  if(useTabTitleOption.length > 0) {
    useTabTitleOption.click(function(e) {
      var isChecked = $(this).is(':checked');

      if(isChecked) {
        $tinymceEl.tinymce().setContent(tabTitleText || tabTitle.text());
      } else {
        $tinymceEl.tinymce().setContent('');
      }
    });
  }

  tabTitle.keyup(function(e) {
    var isChecked = useTabTitleOption.is(':checked');

    tabTitleText = e.target.value;
    if(isChecked) {
      $tinymceEl.tinymce().setContent(e.target.value);
    }
  });
}

function startTinyMCE() {
  var valid_elements = "a[name|href|target|title|onclick],img[class|src|";
  valid_elements += "border=0|alt|title|hspace|vspace|width|height|align|onmouseover|onmouseout|name],";
  valid_elements += "hr[class|width|size|noshade],font[face|size|color|style],span[class|align|style]";


  $('textarea.tinymce').livequery(function() {
    var $tinymceEl = $(this);

    $tinymceEl.tinymce({
      oninit: function() { setupSyncTitle($tinymceEl); },
      mode: "textareas",
      convert_urls: false,
      plugins: "preview,directionality,noneditable,table,paste",
      extended_valid_elements: valid_elements
    });
  });
}

function initialiseQuestionnaireEditPage() {
  $('#change_banner').livequery('click', function(e) {
    e.preventDefault();
    $('#li_banner').show('slow');
  });
}


function initializeDescriptionExtraFieldsHandlers() {
  var changeHandler = function() {
    var $el = $(this);

    if($el.is(':checked')) {
      addLoopTagToTextFields('object_description', $el.siblings('span').html());
    } else {
      removeTagFromTextFields('object_description', $el.siblings('span').html());
    }
  };

  $('.extras').livequery(function() {
    $(this).each(function() { $(this).change(changeHandler); } );
  });
}


function initialiseDefineDependencyPage(targetSectionId) {
  $('#sections_').change(function() {
    var selectedVal = $('#sections_ :selected').val();

    if(selectedVal !== '') {
      $.ajax({
        url:RAILS_ROOT+'/sections/'+selectedVal+'/questions_for_dependency',
        type:'get',
        dataType:'script',
        data: { section_id: targetSectionId}
      });
    } else {
      $('#section_depends_on_question').val('');
      $('#section_depends_on_option').val('');
    }

    $('#section_depends_on_option_value').val('');
  });
}

function initialiseNewQuestionPage() {
  var changeHandler = function() {
    var $el = $(this);

    if($el.is(':checked')) {
      addLoopTagToTextFields('question_title', $el.siblings('span').html());
    } else {
      removeTagFromTextFields('question_title', $el.siblings('span').html());
    }
  };

  $('.var').livequery(function() {
    $(this).each(function() { $(this).change(changeHandler); });
  });
}

function initialiseUsersIndexPage() {
  $("#users_index").tablesorter({
    sortList: [[1,0]],
    widthFixed: false,
    widgets: ['zebra'],
    headers: {0: { sorter: false }}
  });
  initialiseSelectAll();
}

function initialiseAuthorizedSubmittersPage() {
  // Activate user_dialog to use the JQuery.UI Dialog
  initialiseSelectAll();
  $('#user_dialog').dialog({autoOpen:false, resizable:false, modal:true, width: 500, height: 700, overflow: "auto"});

  // Set the "tableSorter" for the table "MyTable"
  // Starts with the sorting on the "Authorizated" Column and the Name Column
  // Sorting is disabled for the first column (the checkboxes)
  $('#myTable').tablesorter({
    sortList: [[1,1], [2,0]],
    widthFixed: false,
    widgets: ['zebra'],
    headers: {0: { sorter: false }}
  });

  // Enable the search field and the "Select Group" filter/search.
  enableSearch();

  // Enable the functions of the buttons "Authorize", "De-Authorize" and "Create!"(groups)
  // These functions will apply to the selected users.
  //authorizationFunctionsHandlers();
  //
  initialiseAuthorizedFilter();

  // Enables the "Select" links: all, none, authorized and unauthorized.
  //checkboxesSelectionHandlers();

  //$('#change_lang').livequery('click', function(e) {
    //e.preventDefault();
    //$('#language_selection').toggle('slow');
  //});

  initialiseSelectAll();
}

function selectOtherField() {
  $('#answer_type_other_required').livequery('change', function() {
    if($(this).is(':checked')) {
      $('#other_text_fields').slideDown('2000');
      $('#other_text_fields').find('.other_text_destroy').each(function() {
        $(this)[0].value ='0';
      });
    } else {
      $('#other_text_fields').slideUp('2000');
      $('#other_text_fields').find('.other_text_destroy').each(function() {
        $(this)[0].value = '1';
      });
    }
  });
}

// Enable the search for the User Management inside a Questionnaire.
function enableSearch() {
  clearSearchFields();

  $('#filter').keyup(function(event) {
    if(event.keyCode === 27 || $(this).val() === '') {
      $(this).val('');

      //we want each row to be visible because if nothing
      // is entered then all rows are matched
      $('tbody tr').show();
    } else {
      $('#groups_list_').val(''); //deselect the group
      filter('tbody tr', $(this).val());
    }
  });

  $('#groups_list_').change(function() {
    var selectedVal = $('#groups_list_ :selected').val();

    if( selectedVal !== '') {
      $('#filter').val('');
      filter_in_group('tbody tr', $(this).val());
    } else {
      $('tbody tr').show();
    }
  });
}

function clearSearchFields() {
  $('#filter').val('');
  $('#groups_list_').val('');

  $('#clear_search').on('click', null, function(e) {
    e.preventDefault();
    clearSearchFields();
    $('tbody tr').show();
  });
}

// Filter results based on query
function filter(selector, query) {
  query = $.trim(query); //trim white spaces
  query = query.replace(/ /gi, '|'); //add OR for regex query

  $(selector).each(function() {
    if($(this).text().search(new RegExp(query, 'i')) < 0) {
      $(this).hide();
      $(this).find("INPUT[type='checkbox']").attr('checked', false); //de-select element.
    } else {
      $(this).show();
    }
  });
}

// Filter results based on query
function filter_in_group(selector, query) {
  query = $.trim(query); //trim white spaces
  query = query.replace(/ /gi, '|'); //add OR for regex query

  $(selector).each(function() {
    if($(this).children('.user_groups').text().search(new RegExp(query, 'i')) < 0) {
      $(this).hide();
      $(this).find("INPUT[type='checkbox']").attr('checked', false); // de-select element.
    } else {
      $(this).show();
    }
  });
}

function authorizationFunctionsHandlers() {
  $('.authorization_buttons').livequery('click',function() {
    var $el = $(this),
        elName = $el.attr('name');

    if(elName !== 'group') {
      $('form#manage').attr('action', RAILS_ROOT+'/authorized_submitters/'+elName);
      $('form#manage').submit();
    } else {
      $('form#manage').attr('action',RAILS_ROOT+'/users/'+elName);
      $('form#manage').submit();
      $('input#group').val('');
    }
  });

  $('#groups_id').livequery('change',function() {
    $('form#manage').attr('action', RAILS_ROOT+'/users/group');
    $('form#manage').submit();

    $('input#group').val('');
    $('#groups_id').val('');
  });
}

function checkboxesSelectionHandlers() {
  $('#check_all').livequery('click', function(e) {
    e.preventDefault();

    $("INPUT[type='checkbox']").each(function() {
      if($(this).parent().parent().is(':visible')) {
        $(this).attr('checked', true);
      }
    });
  });

  $('#uncheck_all').livequery('click', function(e) {
    e.preventDefault();
    $("INPUT[type='checkbox']").attr('checked', false);
  });

  var checkHandler = function(identifier, checkText) {
    return function() {
      e.preventDefault();

      $("INPUT[type='checkbox']").each(function() {
        if($(this).parent().parent().is(':visible')) {
          var the_id = $(this).attr('id').substring(6);

          if($(identifier+the_id).html() === checkText) {
            $(this).attr('checked', true);
          } else {
            $(this).attr('checked', false);
          }
        } else {
          $(this).attr('checked', false);
        }
      });
    }
  };

  $('#check_authorized').livequery('click', checkHandler('#auth_', 'Yes'));
  $('#check_unauthorized').livequery('click', checkHandler('#auth_', 'No'));
  $('#check_authorizing').livequery('click', checkHandler('#auth_', 'Authorizing'));
  $('#check_underway').livequery('#q_status_', checkHandler('#auth_', 'Underway'));
}

function treeAndSpinnerControls() {
  $('a#collapseAll').click(function(e) {
    e.preventDefault();
    $('#tree').dynatree('getRoot').visit(function(dtnode) {
      dtnode.expand(false);
    });

    $('a#expandAll').show();
    $('a#collapseAll').hide();
  });

  $('a#expandAll').click(function(e) {
    e.preventDefault();
    $('#tree').dynatree('getRoot').visit(function(dtnode) {
      dtnode.expand(true);
    });

    $('a#expandAll').hide();
    $('a#collapseAll').show();
  });

  $('a.activate').click(function(e) {
    e.preventDefault();
    var $spinner = $('#spinner');

    if($spinner.length > 0) {
      $spinner.show('slow');
    }

    $.put($(this).attr('href'), $(this).serialize(), null, 'script');
    return false;
  });
}

// Function to display the questionnaire options
function handleQuestionnaireOptions(questionnaireId) {
  // Show add_section Div and render the new section form
  $('#show_add_section').click(function(e) {
    e.preventDefault();

    $('.info-toggle-header').trigger('header:hide');
    collapseInfoGeneratorShowPages();
    if(!$('#add_section').is(':visible')) {
      $('#add_section').empty();

      $.ajax({
        url: RAILS_ROOT+'/questionnaires/'+questionnaireId+'/questionnaire_parts/new',
        type: 'get',
        dataType: 'script',
        data: { part_type: 'Section' }
      });
    }
  });
}

// Handle Section Options
function handleSectionOptions(questionnaireId, questionnairePartId) {

  // Show AddSubSection Div and call the new action on the sections controller
  $('#show_add_sub_section').click(function(e) {
    e.preventDefault();

    collapseInfoGeneratorShowPages();
    $('#add_question').empty();
    $('#add_question').hide();

    $('.info-toggle-header').trigger('header:hide');
    if(!$("#add_section").is(':visible')) {
      $("#add_section").show();

      $.ajax({
        url: RAILS_ROOT+'/questionnaires/'+questionnaireId+'/questionnaire_parts/new/',
        type: 'get',
        dataType: 'script',
        data: {
          part_type: 'Section',
          parent_id: questionnairePartId
        }
      });
    }
  });

  // Show AddQuestion Div and call the new action on the questions controller
  $('#show_add_question').click(function(e) {
    e.preventDefault();

    collapseInfoGeneratorShowPages();
    $("#add_section").empty();
    $("#add_section").hide();

    $('.info-toggle-header').trigger('header:hide');
    if(!$("#add_question").is(':visible')) {
      $("#add_question").show();

      $.ajax({
        url: RAILS_ROOT+'/questionnaires/'+questionnaireId+'/questionnaire_parts/new/',
        type: 'get',
        dataType: 'script',
        data: {
          part_type: 'Question',
          parent_id: questionnairePartId
        }
      });
    }
  });
}

function addOrReplaceLoopTagToTextFields(fieldsClass, tagValue) {
  var oldValue;

  $('.'+fieldsClass).each(function() {
    oldValue = $(this).val();

    if(oldValue.search(/#\[(.*)\]/)!= -1) {
      oldValue = oldValue.replace(/#\[(.*)\]/, '#['+tagValue+']');
    } else {
      oldValue = oldValue + '#['+tagValue+']';
    }

    $(this).val(oldValue);
  });
}

function addLoopTagToTextFields(fieldsClass, tagValue) {
  var oldValue;

  $('.'+fieldsClass).each(function() {
    oldValue = $(this).val();
    oldValue = oldValue + '#['+tagValue+']';

    $(this).val(oldValue);
  });
}

function removeTagFromTextFields(fieldsClass, tag) {
  $('.'+fieldsClass).each(function() {
    if($(this).val().search(new RegExp('#\\[' + tag.toString() + '\\]' )) != -1) {
      $(this).val( $(this).val().replace('#['+tag+']', ''));
    }
  });
}

function removeLoopTagFromTextFields(fieldsClass) {
  $('.'+fieldsClass).each(function() {
    if($(this).val().search(/#\[(.*)\]/) != -1) {
      $(this).val( $(this).val().replace(/#\[(.*)\]/, ''));
    }
  });
}

// Handle Section drop down lists (for when adding a new section or subsection)
function handleSectionDetailsOptions(questionnaireId, canBeDisplayedInTab) {
  // Function to control the "Section Type" Select Box
  $('#part_section_type').change(function() {
    var selectVal = $(this).val();

    switch(selectVal) {
      case '0':
        $('#s_answer_type').hide('slow');
        $('#part_answer_type_type').addClass('hide');
        $('#looping_sources').show('slow');
        $('#answer_type').empty();

        if(canBeDisplayedInTab === 'true') {
          $('#part_display_in_tab').attr('checked', false);
          $('#part_display_in_tab').attr('disabled', true);
          $('#part_starts_collapsed').attr('disabled', false);
        }

        break;
      case '1':
        $('#looping_sources').hide('slow');
        $('#loopingItems').hide('slow');
        $('#part_loop_source_id').val('').addClass('hide');
        $('#part_loop_item_type').val('');

        // remove possible tags from the text fields
        removeLoopTagFromTextFields('section_title');

        $('#looping_categories').hide().empty();
        $('#part_answer_type_type').removeClass('hide');
        $('#s_answer_type').show('slow');

        if(CanBeDisplayedInTab === 'true') {
          $('#part_display_in_tab').attr('disabled', false);
        }

        break;
      default:
        // hide looping related elements and clear the hidden values
        // hide answer type select element and div
        $('#loopingItems').hide('slow');
        $('#looping_sources').hide('slow');
        $('#part_loop_source_id').val('').addClass('hide');
        $('#part_loop_item_type').val('');

        // remove possible tags from the text fields
        removeLoopTagFromTextFields('section_title');

        $('#looping_categories').hide().empty();
        $('#part_answer_type_type').addClass('hide');
        $('#s_answer_type').hide('slow');
        $('#answer_type').empty();

        if(CanBeDisplayedInTab === 'true') {
          $('#part_display_in_tab').attr('disabled', false);
        }
        break;
    }
  });

  // Function to control the 'Answer Type' Select Box  | Displaying the form for adding each type of answer
  $('#part_answer_type_type').change(function() {
    var selectVal = $(this).val(),
        resultVal = selectVal.replace(/Answer/,'');

    $('#answer_type').hide('slow').empty();

    if(resultVal !== '') {
      $.ajax({
        url: RAILS_ROOT+'/'+resultVal.toLowerCase()+'_answers/new/',
        type: 'get',
        dataType: 'script',
        data: {questionnaire_id: questionnaireId}
      });
    }
  });

  $('#part_display_in_tab').change(function() {
    if($(this).is(':checked')) {
      $('#part_starts_collapsed').attr('checked', true);
      $('#part_starts_collapsed').attr('disabled', true);
    } else {
      $('#part_starts_collapsed').attr('disabled', false);
    }
  });
}

// handle the answer_types of the section, when editing a section, receives the section type and the existing answerTypeId
function handleSectionAnswerTypesOptions(sectionType, answerTypeId, questionnaireId) {
  // Function to control the 'Answer Type' Select Box  | Displaying the form for adding each type of answer
  $('#part_answer_type_type').change(function() {
    var selectVal = $(this).val(),
        resultVal = selectVal.replace(/Answer/,'');

    $('#answer_type').hide('slow').empty();

    if(resultVal === '') {
      return;
    }

    if(sectionType === '1') {
      $.ajax({
        url: RAILS_ROOT+'/'+resultVal.toLowerCase()+'_answers/'+answerTypeId+'/edit',
        type: 'get',
        dataType: 'script',
        data: {questionnaire_id: questionnaireId}
      });
    } else {
      $.ajax({
        url: RAILS_ROOT+'/'+resultVal.toLowerCase()+'_answers/new/',
        type: 'get',
        dataType: 'script',
        data: {questionnaire_id: questionnaireId}
      });
    }
  });
}

// Add new Questionnaire (creating new tree) Passing questionnaire: name and id
function createNewTree(name, id) {
  var ellipsis = "";

  //show Tree Options
  $("#tree_options").show();
  $("#tree_col").show();

  if(name.length > 35) {
    ellipsis = "...";
  }

  //Instantiate the tree with the questionnaire as root
  $("#tree").dynatree({
    title: name.substring(0,35)+ellipsis,
    rootVisible: true,
    activeVisible: true,
    clickFolderMode: 3,
    expanded: true,
    onActivate: function(dtnode) {
      var rootNode = $("#tree").dynatree("getRoot");

      if(dtnode === rootNode) {
        $.ajax({url: RAILS_ROOT+'/questionnaires/'+id, type:'get', dataType:'script'});
      } else if(dtnode.data.isFolder) {
        $.ajax({url: RAILS_ROOT+'/sections/'+dtnode.data.key, type: 'get', dataType: 'script'});
      } else {
        var key = (dtnode.data.key).toString().substring(1);
        $.ajax({url: RAILS_ROOT+'/questions/'+key, type: 'get', dataType: 'script'});
      }
    }
  });
}

// load the tree structure with an existing questionnaire
function loadTree(name, id, activateRoot, treeLoaded) {
  // show Tree Options
  $('#tree_options').show();
  $('#tree_col').show();

  // verify if the tree exists. If the tree root is the same
  // as this questionnaire's name. If so don't do anything. Otherwise, build the tree
  var old_call = null;
  if(!treeLoaded) {
    var ellipsis = '';
    if(name.length > 35) {
      ellipsis = '...';
    }

    $('#tree').dynatree({
      title: name.substring(0,35)+ellipsis,
      rootVisible: true,
      activeVisible: true,
      expanded: true,
      clickFolderMode: 1,
      onActivate: function(dtnode) {
        // abort previous running ajax calls. To avoid loop between sections/questions.
        if(old_call !== null) {
          old_call.abort();
        }

        var rootNode = $('#tree').dynatree('getRoot');

        if(dtnode === rootNode) {
          old_call = $.get(RAILS_ROOT+'/questionnaires/'+id, null, null, 'script');
        } else if(dtnode.data.isFolder) {
          old_call = $.get(RAILS_ROOT+'/sections/'+dtnode.data.key, null, null, 'script');
        } else if(!(dtnode.data.isFolder)) {
          var key = (dtnode.data.key).toString().substring(1);
          old_call = $.get(RAILS_ROOT+'/questions/'+key, null, null, 'script');
        }
      },
      initAjax: {
        url: RAILS_ROOT+'/questionnaires/'+id+'/tree/',
        dataType: 'jsonp'
      }
    });
  }

  if(activateRoot) {
    $('#tree').dynatree('getRoot').activate();
  }
}

// load the tree structure with an existing questionnaire - And activating a specific node
function loadTreeAndActivateNode(name, id, nodeToActivate) {
  // show Tree Options
  $('#tree_options').show();
  $('#tree_col').show();

  // verify if the tree exists. If the tree root is the same as this
  // questionnaire's name. If so don't do anything. Otherwise, build the tree
  var root = $('#tree').dynatree('getRoot');
  var old_call = null;

  if(root.visit === undefined) {
    var ellipsis = '';
    if(name.length > 35) {
      ellipsis = '...';
    }

    $('#tree').dynatree({
      title: name.substring(0,35)+ellipsis,
      rootVisible: true,
      activeVisible: true,
      expanded: true,
      clickFolderMode: 1,
      onActivate: function(dtnode) {
        // abort previous running ajax calls. To avoid loop between sections/questions.
        if(old_call !== null) {
          old_call.abort();
        }

        var rootNode = $('#tree').dynatree('getRoot');

        if(dtnode === rootNode) {
          old_call = $.get(RAILS_ROOT+'/questionnaires/'+id, null, null, 'script');
        } else if(dtnode.data.isFolder) {
          old_call = $.get(RAILS_ROOT+'/sections/'+dtnode.data.key, null, null, 'script');
        } else if(!(dtnode.data.isFolder)) {
          var key = (dtnode.data.key).toString().substring(1);
          old_call = $.get(RAILS_ROOT+'/questions/'+key, null, null, 'script');
        }
      },
      initAjax: {
        url: RAILS_ROOT+'/questionnaires/'+id+'/tree/',
        dataType: 'jsonp',
        data: { activate: nodeToActivate }
      }
    });
  }
}

// Update node info in the tree
function updateTreeNode(name) {
  var tree = $("#tree").dynatree("getTree"),
      node = tree.getActiveNode(),
      ellipsis = "";

  if(name.length > 25) {
    ellipsis = "...";
  }

  node.data.title = name.substring(0,25) + ellipsis;
  node.data.tooltip = name;
  node.render(false);
}

// add a new Section to the tree
function addNodeToTree(name, id, hasParent) {
  var node;
  if(hasParent === '0') {
    node = $('#tree').dynatree('getRoot');
  } else {
    node = $('#tree').dynatree('getActiveNode');
  }

  var ellipsis = '';
  if(name.length > 25) {
    ellipsis = '...';
  }

  node.addChild({
    title: name.substring(0,25)+ellipsis,
    tooltip: name,
    isFolder: true,
    activate: true,
    key: id,
    expand: true
  });
}

// updates the submission page of a user, with the links to the pdf files.
function updateUserSubmissionPage(userId) {
  setTimeout(function() {
    $('#questionnaires_for_submission').addClass('no_dialog');

    $.ajax({
      url: RAILS_ROOT+'/users/'+userId+'/update_submission_page/',
      type: 'get',
      dataType: 'script'
    });

    $('#questionnaires_for_submission').removeClass('no_dialog');

    if($('#questionnaires_for_submission.set_update_page').length > 0) {
      updateUserSubmissionPage(userId);
    }
  }, 60000);
}

function initialiseHideDisplayLangFields() {
  $('a.display_lang').livequery(function() {
    $(this).each(function() {
      $(this).click(function(e) {
        e.preventDefault();

        var $el = $(this),
            $fieldsForId = $('#fields_for_'+$el.attr('id'));

        if($fieldsForId.is(':visible')) {
          $fieldsForId.slideUp('2000');
          $el.html($el.html().replace("fa-caret-up","fa-caret-down"));
        } else {
          $fieldsForId.slideDown('2000');
          $el.html($el.html().replace("fa-caret-down","fa-caret-up"));
        }
      });
    });
  });

  $('a.show_all_lang_fields').livequery('click', function(e) {
    e.preventDefault();

    $(this).parent().next().find('div.lang_fields').each(function() {
      $(this).slideDown('2000');
    });

    $(this).parent().find('a.display_lang, a.control_lang_display').each(function() {
      $(this).html($(this).html().replace("fa-caret-down","fa-caret-up"));
    });
  });

  $('a.hide_all_lang_fields').livequery('click', function(e) {
    e.preventDefault();

    $(this).parent().next().find('div.lang_fields').each(function() {
      $(this).slideUp('2000');
    });

    $(this).parent().find('a.display_lang, a.control_lang_display').each(function() {
      $(this).html($(this).html().replace("fa-caret-up","fa-caret-down"));
    });
  });
}

function answerTypeGrid(columnNames, columnModel, theDataStub, gridData, tableID, tableCaption, addButton, removeButton, mainAssociation, secondaryAssociation, updateSortIndex, attributeField) {
  $('#'+tableID).jqGrid({
    data: gridData,
    datatype: 'local',
    colNames: columnNames,
    colModel: columnModel,
    altRows: true,
    cellEdit: true,
    cellsubmit: 'clientArray',
    afterSaveCell: function(rowId, cellname, value, iRow, iCol) {
      $('#answer_type_'+mainAssociation+'_attributes_'+rowId+'_'+secondaryAssociation+'_attributes_'+(iCol-(updateSortIndex ? 2 : 1))+'_'+attributeField).val(value);
    },
    editurl: 'clientArray',
    multiselect: true,
    caption: tableCaption,
    width: '300'
  });

  $('#'+addButton).click(function(e) {
    e.preventDefault();

    var template = $('#' + mainAssociation + '_fields_template').html(),
        regexp = new RegExp('new_' + mainAssociation, 'g'),
        newId = new Date().getTime();

    // remove class 'hide' from the required fields
    // the class is set to hide, to avoid the validator to try and validate the template
    $(this).parent().after(template.replace(regexp, newId));

    theDataStub[0].id = newId;

    if(updateSortIndex) {
      var totalRecords = $('#'+tableID).jqGrid('getGridParam', 'records');
      theDataStub[0].Index = totalRecords;
      $('#answer_type_'+mainAssociation+'_attributes_'+newId+'_sort_index').val(totalRecords);
    }

    $('#'+tableID).jqGrid('addRowData', 'id', theDataStub );
  });

  $('#'+removeButton).click(function(e) {
    e.preventDefault();

    var s = $('#'+tableID).jqGrid('getGridParam', 'selarrrow');

    for(var i = (s.length-1); i>=0; i--) {
      $('#answer_type_'+mainAssociation+'_attributes_'+s[i]+'__destroy').val('1');
      $('#'+tableID).jqGrid('delRowData', s[i]);
    }

    if(updateSortIndex) {
      var remaining_objects = $('#'+tableID).jqGrid('getDataIDs');

      for(i = (remaining_objects.length-1); i>=0; i--) {
        var the_index = $('#'+tableID).jqGrid('getInd', remaining_objects[i])-1;
        var row = $('#'+tableID).jqGrid('getRowData', remaining_objects[i]);

        if(row.Index != the_index) {
          row.Index = the_index;
          $('#'+tableID).jqGrid('setRowData', remaining_objects[i], row);
          $('#answer_type_'+mainAssociation+'_attributes_'+remaining_objects[i]+'_sort_index').val(the_index);
        }
      }
    }
  });
}

/*
 Grabbed here: http://gist.github.com/110410
 Info here: http://www.notgeeklycorrect.com/english/2009/05/18/beginners-guide-to-jquery-ruby-on-rails/

 Jquery and Rails powered default application.js
 Easy Ajax replacement for remote_functions and ajax_form based on class name
 All actions will reply to the .js format
 Unobtrusive, will only works if Javascript enabled, if not, respond to an HTML as a normal link
 respond_to do |format|
 format.html
 format.js {render :layout => false}
 end
 */

/*
 Submit a form with Ajax
 Use the class ajaxForm in your form declaration
 <% form_for @comment,:html => {:class => "ajaxForm"} do |f| -%>
 */
jQuery.fn.submitWithAjax = function() {
  this.unbind('submit', false);
  this.submit(function() {
    $.post(this.action, $(this).serialize(), null, 'script');
    return false;
  });

  return this;
};

/*
 Retreive a page with get
 Use the class get in your link declaration
 <%= link_to 'My link', my_path(),:class => 'get' %>
 */
jQuery.fn.getWithAjax = function() {
  this.unbind('click', false);
  this.click(function() {
    $.get($(this).attr('href'), $(this).serialize(), null, 'script');
    return false;
  });

  return this;
};

/*
 Post data via html
 Use the class post in your link declaration
 <%= link_to 'My link', my_new_path(),:class => 'post' %>
 */
jQuery.fn.postWithAjax = function() {
  this.unbind('click', false);
  this.click(function() {
    $.post($(this).attr('href'), $(this).serialize(), null, 'script');
    return false;
  });

  return this;
};

/*
 Update/Put data via html
 Use the class put in your link declaration
 <%= link_to 'My link', my_update_path(data),:class => 'put',:method => :put %>
 */
jQuery.fn.putWithAjax = function() {
  this.unbind('click', false);
  this.click(function() {
    $.put($(this).attr('href'), $(this).serialize(), null, 'script');
    return false;
  });

  return this;
};

/*
 Delete data
 Use the class delete in your link declaration
 <%= link_to 'My link', my_destroy_path(data),:class => 'delete',:method => :delete %>
 */
jQuery.fn.deleteWithAjax = function() {
  this.removeAttr('onclick');
  this.unbind('click', false);

  this.click(function() {
    $.delete_($(this).attr('href'), $(this).serialize(), null, 'script');
    return false;
  });

  return this;
};
