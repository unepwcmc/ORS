// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults


/*
 My onw functions. ORT
 */

//When an option like "Add Section" or "Add Question"
//is clicked the info of the questionnaire/section/question is
//Collapsed to save space
function collapseInfoGeneratorShowPages(){
    $(".info").each(function(){
        $(this).slideUp("2000", function(){
            $(this).prev('div').css("border-bottom-width","1px");
        });
    });
    $(".show_info").each(function(){
        $(this).show();
        $(this).siblings(".hide_info").hide();
    });
}

function setupSyncTitle(t) {
  var use_tab_title_option = t.siblings('.use-tab-title'),
    tab_title = t.parent().prev().find('.tab-title'),
    tab_title_text;
  if (use_tab_title_option.length > 0) {
    use_tab_title_option.click(function(e) {
      var is_checked = $(this).is(':checked');
      if (is_checked) {
        t.tinymce().setContent(tab_title_text || tab_title.text());
      } else {
        t.tinymce().setContent('');
      }
    });
  }
  tab_title.keyup(function(e) {
    var is_checked = use_tab_title_option.is(':checked');
    tab_title_text = e.target.value;
    if (is_checked) {
      t.tinymce().setContent(e.target.value);
    }
  });
}

function startTinyMCE(){
    $('textarea.tinymce').livequery(function(){
        var t = $(this);
        t.tinymce({
            oninit: function(){setupSyncTitle(t);},
            mode: "textareas",
            convert_urls: false,
            plugins: "preview,directionality,noneditable,table,paste",
            extended_valid_elements:"a[name|href|target|title|onclick],img[class|src|"+
                                    "border=0|alt|title|hspace|vspace|width|height|align|onmouseover|onmouseout|name],"+
                                    "hr[class|width|size|noshade],font[face|size|color|style],span[class|align|style]"
        });
    });
}

function initialiseQuestionnaireEditPage(){
    $("#change_banner").livequery('click', function(e){
        e.preventDefault();
        $("#li_banner").show("slow");
    });
}


function initializeDescriptionExtraFieldsHandlers(){
    $('.extras').livequery(function(){
        $(this).each(function(){
            $(this).change(function(){
                if($(this).is(':checked'))
                    addLoopTagToTextFields('object_description',$(this).siblings('span').html());
                else
                    removeTagFromTextFields('object_description',$(this).siblings('span').html());
            });
        });
    });
}
/*
 Functions to handle the multi-languages feature when adding a questionnaire
 */
function initialiseQuestionnaireNewPage(){

    //displays the div with the extra languages
    $("#show_more_languages").click(function(e){
        e.preventDefault();
        $("#more_languages").show("slow");
        $(".add_languages_buttons").toggle();
    });
    //hides the div with extra languages and de-selects the languages that were previously selected
    $("#hide_more_languages").click(function(e){
        e.preventDefault();
        $("#more_languages").hide("slow");
        $(".add_languages_buttons").toggle();
        $(".include_check_box").each(function(){
            $(this).attr('checked', false);
            var hidden_field = $(this).prev("input[type='hidden']")[0];
            hidden_field.value = '1'; //set to destroy
        });
    });
    //when an "include_check_box" is clicked the value of the hidden "_destroy" field is set to 0
    //so that the language is added to the new questionnaire
    //the default of the hidden "_destroy" field is 1, because it is assumed that the user won't want those languages
    $(".include_check_box").each(function(){
        $(this).change(function(){
            var hidden_field = $(this).prev("input[type='hidden']")[0];
            if(hidden_field)
            {
                if($(this).is(":checked"))
                    hidden_field.value = '0';
                else
                    hidden_field.value = '1';
            }
        });
    });
    //When the main language is selected the "extra language" field that matches will be disabled, because there can only
    // be one input of each language.
    $("#questionnaire_questionnaire_fields_attributes_0_language").change(function(){
        var value = $(this).val();
        //starts by enabling all of the extra-languages inputs
        $(".extra_lang_div").each(function(){
            $(this).find("textarea").each(function(){
                $(this).attr("disabled", false);
            });
            //$(this).find("textarea").css('background-color', "#fff");
            $(this).children().each(function(){
                $(this).css("background-color", "#fff");
            });
        });
        $(".include_check_box").each(function(){
            $(this).attr("disabled", false);
        });
        if(value !== "")
        {
            var $field_value = $("#field_"+value);
            var $include_value = $("#include_"+value);
            //disable the one that matches the selected value
            $field_value.find("textarea").each(function(){
                $(this).attr("disabled", true);
                //$(this).css('background-color', "#ddd");
            });
            $field_value.children().each(function(){
                $(this).css("background-color", "#ddd");
            });
            $include_value.attr('checked',false)
                    .attr('disabled',true)
                    .prev("input[type='hidden']")[0].value = '1';
        }
        //change the title text_field text direction to "right-to-left" when the selected language is arabic
        var $this_parents = $(this).parents("#default_language");
        if(value === "ar")
        {
            $this_parents.find("textarea").attr("dir", "rtl");
            $this_parents.find("input").attr("dir", "rtl");
        }
        else
        {
            $this_parents.find("textarea").attr("dir", "ltr");
            $this_parents.find("input").attr("dir", "ltr");
        }
    });
}

function initialiseDefineDependencyPage(target_section_id){
    $("#sections_").change(function(){
        var selectedVal = $("#sections_ :selected").val();
        if(selectedVal !== ""){
            $.ajax({url:RAILS_ROOT+"/sections/"+selectedVal+"/questions_for_dependency", type:"get", dataType:"script", data: { section_id: target_section_id}});
        } else
        {
            $("#section_depends_on_question").val("");
            $("#section_depends_on_option").val("");
        }
        $("#section_depends_on_option_value").val("");
    });
}

function initialiseNewQuestionPage(){
    $('.var').livequery(function(){
        $(this).each(function(){
            $(this).change(function(){
                if($(this).is(':checked'))
                    addLoopTagToTextFields('question_title',$(this).siblings('span').html());
                else
                    removeTagFromTextFields('question_title',$(this).siblings('span').html());
            });
        });
    });
}


function initialiseUsersIndexPage(){
    $("#users_index").tablesorter({
        sortList: [[1,0]], widthFixed: false, widgets: ['zebra'],
        headers: { 0: { sorter: false }}
    });
}


function initialiseShowQuestionnairePage(){
}

function initialiseAuthorizedSubmittersPage(){
    //Activate user_dialog to use the JQuery.UI Dialog
    $("#user_dialog").dialog({autoOpen:false, resizable:false, modal:true, width: 500 });

    //Clicking on the "add_new_user" link it will open the Dialog with the New User Form.
    $("#add_new_user").livequery('click',function(e){
        e.preventDefault();
        $("#user_dialog").dialog("open");
    });


    //Set the "tableSorter" for the table "MyTable"
    // Starts with the sorting on the "Authorizated" Column and the Name Column
    // Sorting is disabled for the first column (the checkboxes)
    $("#myTable").tablesorter({
        sortList: [[1,1], [2,0]], widthFixed: false, widgets: ['zebra'],
        headers: { 0: { sorter: false }}
    });

    //Enable the search field and the "Select Group" filter/search.
    enableSearch();

    //Enable the functions of the buttons "Authorize", "De-Authorize" and "Create!"(groups)
    //These functions will apply to the selected users.
    authorizationFunctionsHandlers();

    //Enables the "Select" links: all, none, authorized and unauthorized.
    checkboxesSelectionHandlers();

    $("#change_lang").livequery('click',function(e){
        e.preventDefault();
        $("#language_selection").toggle("slow");
    });
}

function initialiseQuestionnairesIndexPage(){
    $("#questionnaires_index").tablesorter({
        sortList: [[4,1]],
        widgets: ['zebra'],
        headers: { 5: { sorter: false }}});
}

function selectOtherField(){
    $("#answer_type_other_required").livequery('change', function(){
        if($(this).is(':checked')){
            $("#other_text_fields").slideDown('2000');
            $("#other_text_fields").find(".other_text_destroy").each(function(){
                $(this)[0].value ="0";
            });
        }
        else
        {
            $("#other_text_fields").slideUp('2000');
            $("#other_text_fields").find(".other_text_destroy").each(function(){
                $(this)[0].value ="1";
            });
        }
    });
}

//Enable the search for the User Management inside a Questionnaire.
function enableSearch(){
    clearSearchFields();
    $("#filter").keyup(function(event){
        if(event.keyCode === 27 || $(this).val() === ''){
            $(this).val('');
            //we want each row to be visible because if nothing
            // is entered then all rows are matched
            $('tbody tr').show();
        }
        else
        {
            $("#groups_list_").val(""); //deselect the group
            filter('tbody tr', $(this).val());
        }
    });
    $("#groups_list_").change(function(){
        var selectedVal = $("#groups_list_ :selected").val();
        if( selectedVal !== "")
        {
            $("#filter").val("");
            filter_in_group('tbody tr', $(this).val());
        }
        else
        {
            $("tbody tr").show();
        }
    });
}

function clearSearchFields(){
    $("#filter").val("");
    $("#groups_list_").val("");
    $("#clear_search").on('click', null, function(e){
        e.preventDefault();
        clearSearchFields();
        $("tbody tr").show();
    });
}
//Filter results based on query
function filter(selector, query){
    query = $.trim(query); //trim white space)
    query = query.replace(/ /gi, '|');//add OR for regex query
    $(selector).each(function(){
        if($(this).text().search(new RegExp(query, 'i')) < 0)
        {
            $(this).hide();
            $(this).find("INPUT[type='checkbox']").attr('checked', false); //de-select element.
        }
        else
        {
            $(this).show();
        }
    });
}
//Filter results based on query

function filter_in_group(selector, query){
    query = $.trim(query); //trim white space)
    query = query.replace(/ /gi, '|');//add OR for regex query
    $(selector).each(function(){
        if($(this).children('.user_groups').text().search(new RegExp(query, 'i')) < 0)
        {
            $(this).hide();
            $(this).find("INPUT[type='checkbox']").attr('checked', false); //de-select element.
        }
        else
        {
            $(this).show();
        }
    });
}

function authorizationFunctionsHandlers(){
    $(".authorization_buttons").livequery('click',function(){
        if($(this).attr('name') != 'group')
        {
            $("form#manage").attr('action', RAILS_ROOT+'/authorized_submitters/'+$(this).attr('name'));
            $("form#manage").submit();
        }
        else
        {
            $("form#manage").attr('action',RAILS_ROOT+'/users/'+$(this).attr('name'));
            $("form#manage").submit();
            $("input#group").val("");
        }
    });

    $("#groups_id").livequery('change',function(){
        $("form#manage").attr('action', RAILS_ROOT+'/users/group');
        $("form#manage").submit();
        $("input#group").val("");
        $("#groups_id").val('');
    });
}

function checkboxesSelectionHandlers(){
    $("#check_all").livequery('click',function(e){
        e.preventDefault();
        $("INPUT[type='checkbox']").each(function(){
            if($(this).parent().parent().is(":visible"))
                $(this).attr('checked', true);
        });
    });
    $("#uncheck_all").livequery('click', function(e){
        e.preventDefault();
        $("INPUT[type='checkbox']").attr('checked', false);
    });
    $("#check_authorized").livequery('click', function(e){
        e.preventDefault();
        $("INPUT[type='checkbox']").each(function(){
            if($(this).parent().parent().is(":visible"))
            {
                var the_id = $(this).attr("id").substring(6);
                if($("#auth_"+the_id).html() === "Yes")
                    $(this).attr('checked', true);
                else
                    $(this).attr('checked', false);
            }
            else
                $(this).attr('checked', false);
        });
    });
    $("#check_unauthorized").livequery('click', function(e){
        e.preventDefault();
        $("INPUT[type='checkbox']").each(function(){
            if($(this).parent().parent().is(":visible"))
            {
                var the_id = $(this).attr("id").substring(6);
                if($("#auth_"+the_id).html() === "No"){
                    $(this).attr('checked', true);
                } else{
                    $(this).attr('checked', false);
                }
            }
            else{
                $(this).attr('checked', false);
            }
        });
    });

    $("#check_authorizing").livequery('click', function(e){
        e.preventDefault();
        $("INPUT[type='checkbox']").each(function(){
            if($(this).parent().parent().is(":visible"))
            {
                var the_id = $(this).attr("id").substring(6);
                if($("#auth_"+the_id).html() === "Authorizing"){
                    $(this).attr('checked', true);
                } else{
                    $(this).attr('checked', false);
                }
            }
            else{
                $(this).attr('checked', false);
            }
        });
    });

    $("#check_underway").livequery('click', function(e){
        e.preventDefault();
        $("INPUT[type='checkbox']").each(function(){
            if($(this).parent().parent().is(":visible"))
            {
                var the_id = $(this).attr("id").substring(6);
                if($("#q_status_"+the_id).html() === "Underway")
                    $(this).attr('checked', true);
                else
                    $(this).attr('checked', false);
            }
            else
                $(this).attr('checked',false);
        });
    });

    $("#check_underway").livequery('click', function(e){
        e.preventDefault();
        $("INPUT[type='checkbox']").each(function(){
            if($(this).parent().parent().is(":visible"))
            {
                var the_id = $(this).attr("id").substring(6);
                if($("#q_status_"+the_id).html() === "Underway")
                    $(this).attr('checked', true);
                else
                    $(this).attr('checked', false);
            }
            else
                $(this).attr('checked',false);
        });
    });
}

function treeAndSpinnerControls(){
    $("a#collapseAll").click(function(){
        $("#tree").dynatree("getRoot").visit(function(dtnode){
            dtnode.expand(false);
        });
        $("a#expandAll").show();
        $("a#collapseAll").hide();
    });
    $("a#expandAll").click(function(){
        $("#tree").dynatree("getRoot").visit(function(dtnode){
            dtnode.expand(true);
        });
        $("a#expandAll").hide();
        $("a#collapseAll").show();
    });

    $('a.activate').click(function(e){
        e.preventDefault();
        if(('#spinner').length > 0)
            $("#spinner").show("slow");
        $.put($(this).attr("href"), $(this).serialize(), null, "script");
        return false;
    });
}

// Function to display the questionnaire options
function handleQuestionnaireOptions(questionnaire_id){
    //Show add_section Div and render the new section form
    $("#show_add_section").click(function(e){
        e.preventDefault();
        collapseInfoGeneratorShowPages();
        if(!$("#add_section").is(':visible'))
        {
            $("#add_section").empty();
            //$("#add_section").show("slow");
            //$("#add_section").append("<%#= escape_javascript()%>");
            //enable links to work on the new section form.
            //$.ajax({url: RAILS_ROOT+'/sections/new/'+questionnaire_id, type: 'get', dataType: 'script'})
            $.ajax({url: RAILS_ROOT+'/questionnaires/'+questionnaire_id+'/questionnaire_parts/new',
                type: 'get',
                dataType: 'script',
                data: {
                    part_type: "Section"
                }
            });
        }
    });
}

//Handle Section Options
function handleSectionOptions(questionnaire_id, questionnaire_part_id){
    //Show AddSubSection Div and call the new action on the sections controller
    $("#show_add_section").click(function(e){
        e.preventDefault();
        collapseInfoGeneratorShowPages();
        $("#add_question").empty();
        $("#add_question").hide();
        if(!$("#add_section").is(':visible'))
        {
            $("#add_section").show();
            //$.ajax({url: RAILS_ROOT+'/sections/'+section_id+'/new/', type: 'get', dataType: 'script'})
            $.ajax({url: RAILS_ROOT+'/questionnaires/'+questionnaire_id+'/questionnaire_parts/new/',
                type: 'get',
                dataType: 'script',
                data: {
                    part_type: "Section",
                    parent_id: questionnaire_part_id
                }
            });
        }
    });
    //Show AddQuestion Div and call the new action on the questions controller
    $("#show_add_question").click(function(e){
        e.preventDefault();
        collapseInfoGeneratorShowPages();
        $("#add_section").empty();
        $("#add_section").hide();
        if(!$("#add_question").is(':visible'))
        {
            $("#add_question").show();
            //$.ajax({url: RAILS_ROOT+'/questions/new/'+section_id, type: 'get', dataType: 'script'})
            $.ajax({url: RAILS_ROOT+'/questionnaires/'+questionnaire_id+'/questionnaire_parts/new/',
                type: 'get',
                dataType: 'script',
                data: {
                    part_type: "Question",
                    parent_id: questionnaire_part_id
                }
            });
        }
    });
}

function addOrReplaceLoopTagToTextFields(fields_class, tag_value){
    var oldValue;
    $("."+fields_class).each(function(){
        oldValue = $(this).val();
        if(oldValue.search(/#\[(.*)\]/)!= -1){
            oldValue = oldValue.replace(/#\[(.*)\]/,"#["+tag_value+"]");
        } else{
            oldValue = oldValue + "#["+tag_value+"]";
        }
        $(this).val(oldValue);
    });
}

function addLoopTagToTextFields(fields_class, tag_value){
    var oldValue;
    $("."+fields_class).each(function(){
        oldValue = $(this).val();
        oldValue = oldValue + "#["+tag_value+"]";
        $(this).val(oldValue);
    });
}

function removeTagFromTextFields(fields_class, tag) {
    $("."+fields_class).each(function(){
        if($(this).val().search(new RegExp("#\\[" + tag.toString() + "\\]" )) != -1)
            $(this).val($(this).val().replace("#["+tag+"]", ""));
    });
}

function removeLoopTagFromTextFields(fields_class) {
    $("."+fields_class).each(function(){
        if($(this).val().search(/#\[(.*)\]/) != -1)
            $(this).val($(this).val().replace(/#\[(.*)\]/, ""));
    });
}
//Handle Section drop down lists (for when adding a new section or subsection)
function handleSectionDetailsOptions(questionnaireId, can_be_displayed_in_tab){
    //Function to control the "Section Type" Select Box
    $("#part_section_type").change(function(){
        var selectVal = $(this).val();
        switch(selectVal)
        {
            case "0":
                $("#s_answer_type").hide("slow");
                $("#part_answer_type_type").addClass("hide");
                $("#looping_sources").show("slow");
                $("#answer_type").empty();
                if(can_be_displayed_in_tab === 'true')
                {
                    $("#part_display_in_tab").attr('checked', false);
                    $("#part_display_in_tab").attr('disabled', true);
                    $("#part_starts_collapsed").attr("disabled", false);
                }
                break;
            case "1":
                $("#looping_sources").hide("slow");
                $("#loopingItems").hide("slow");
                $("#part_loop_source_id").val("").addClass("hide");
                $("#part_loop_item_type").val("");
                //remove possible tags from the text fields
                removeLoopTagFromTextFields("section_title");
                $("#looping_categories").hide().empty();
                $("#part_answer_type_type").removeClass("hide");
                $("#s_answer_type").show("slow");
                if(can_be_displayed_in_tab === 'true')
                    $("#part_display_in_tab").attr('disabled', false);
                break;
            default:
                //hide looping related elements and clear the hidden values
                //hide answer type select element and div
                $("#loopingItems").hide("slow");
                $("#looping_sources").hide("slow");
                $("#part_loop_source_id").val("").addClass("hide");
                $("#part_loop_item_type").val("");
                //remove possible tags from the text fields
                removeLoopTagFromTextFields("section_title");
                $("#looping_categories").hide().empty();
                $("#part_answer_type_type").addClass("hide");
                $("#s_answer_type").hide("slow");
                $("#answer_type").empty();
                if(can_be_displayed_in_tab === 'true' )
                    $("#part_display_in_tab").attr('disabled', false);
                break;
        }
    });
    //Function to control the "Answer Type" Select Box  | Displaying the form for adding each type of answer
    $("#part_answer_type_type").change(function(){
        var selectVal = $(this).val();
        var resultVal = selectVal.replace(/Answer/,"");
        $("#answer_type").hide('slow').empty();
        if(resultVal !== ""){
            //$("#answerType").append("<%#= escape_javascript(render(:partial => "multi_answers/new", :locals => {:question => @question}))%>");            break;
            $.ajax({url: RAILS_ROOT+'/'+resultVal.toLowerCase()+'_answers/new/', type: 'get', dataType: 'script', data: {questionnaire_id: questionnaireId}});
        }
    });

    $("#part_display_in_tab").change(function(){
        if($(this).is(':checked'))
        {
            $("#part_starts_collapsed").attr("checked", true);
            $("#part_starts_collapsed").attr("disabled", true);
        }
        else
        {
            $("#part_starts_collapsed").attr("disabled", false);
        }
    });
}

//handle the answer_types of the section, when editing a section, receives the section type and the existing answer_type_id
function handleSectionAnswerTypesOptions(section_type, answer_type_id, questionnaireId)
{
    //Function to control the "Answer Type" Select Box  | Displaying the form for adding each type of answer
    $("#part_answer_type_type").change(function(){
        var selectVal = $(this).val();
        var resultVal = selectVal.replace(/Answer/,"");
        $("#answer_type").hide('slow').empty();
        if(resultVal !== "")
        {
            if(section_type === "1")
            {
                $.ajax({url: RAILS_ROOT+'/'+resultVal.toLowerCase()+'_answers/'+answer_type_id+'/edit', type: 'get', dataType: 'script', data: {questionnaire_id: questionnaireId}});
            }
            else
            {
                $.ajax({url: RAILS_ROOT+'/'+resultVal.toLowerCase()+'_answers/new/', type: 'get', dataType: 'script', data: {questionnaire_id: questionnaireId}});
            }
        }
    });
}

//Add new Questionnaire (creating new tree) Passing questionnaire: name and id
function createNewTree(name, id){
    $("#tree_col").show();
    //show Tree Options
    $("#tree_options").show();
    var new_name = "";
    if(name.length > 35)
        new_name = "...";
    //Instantiate the tree with the questionnaire as root
    $("#tree").dynatree({
        title: name.substring(0,35)+ new_name,
        rootVisible: true,
        activeVisible: true,
        clickFolderMode: 3,
        expanded: true,
        onActivate: function(dtnode) {
            var rootNode = $("#tree").dynatree("getRoot");
            if(dtnode === rootNode)
            {
                $.ajax({url: RAILS_ROOT+'/questionnaires/'+id, type:'get', dataType:'script'});
            }
            else if(dtnode.data.isFolder)
            {
                $.ajax({url: RAILS_ROOT+'/sections/'+dtnode.data.key, type: 'get', dataType: 'script'});
            }
            else
            {
                var key = (dtnode.data.key).toString().substring(1);
                $.ajax({url: RAILS_ROOT+'/questions/'+key, type: 'get', dataType: 'script'});
            }
        }
    });
}

//load the tree structure with an existing questionnaire
function loadTree(name, id, activate_root, tree_loaded){
    $("#tree_col").show();
    //show Tree Options
    $("#tree_options").show();
    //verify if the tree exists. If the tree root is the same as this questionnaire's name. If so don't do anything. Otherwise, build the tree
    var old_call = null;
    if(!tree_loaded)
    {
        var new_name = "";
        if(name.length > 35)
            new_name = "...";
        $("#tree").dynatree({
            title: name.substring(0,35)+ new_name,
            rootVisible: true,
            activeVisible: true,
            expanded: true,
            clickFolderMode: 1,
            onActivate: function(dtnode) {
                //abort previous running ajax calls. To avoid loop between sections/questions.
                if(old_call !== null)
                    old_call.abort();
                var rootNode = $("#tree").dynatree("getRoot");
                if(dtnode === rootNode)
                {
                    old_call = $.get(RAILS_ROOT+'/questionnaires/'+id, null, null, 'script');
                }
                else if(dtnode.data.isFolder)
                {
                    old_call = $.get(RAILS_ROOT+'/sections/'+dtnode.data.key, null, null, 'script');
                }
                else if(!(dtnode.data.isFolder))
                {
                    var key = (dtnode.data.key).toString().substring(1);
                    old_call = $.get(RAILS_ROOT+'/questions/'+key, null, null, 'script');
                }
            },
            initAjax: {
                url: RAILS_ROOT+'/questionnaires/'+id+'/tree/',
                dataType: "jsonp"
            }
        });
    }
    if(activate_root)
        $("#tree").dynatree("getRoot").activate();
}

//load the tree structure with an existing questionnaire - And activating a specific node
function loadTreeAndActivateNode(name, id, nodeToActivate){
    $("#tree_col").show();
    //show Tree Options
    $("#tree_options").show();
    //verify if the tree exists. If the tree root is the same as this questionnaire's name. If so don't do anything. Otherwise, build the tree
    var root = $("#tree").dynatree("getRoot");
    var old_call = null;
    if(root === undefined)
    {
        var new_name = "";
        if(name.length > 35)
            new_name = "...";
        $("#tree").dynatree({
            title: name.substring(0,35)+ new_name,
            rootVisible: true,
            activeVisible: true,
            expanded: true,
            clickFolderMode: 1,
            onActivate: function(dtnode) {
                //abort previous running ajax calls. To avoid loop between sections/questions.
                if(old_call !== null)
                    old_call.abort();
                var rootNode = $("#tree").dynatree("getRoot");
                if(dtnode === rootNode)
                {
                    old_call = $.get(RAILS_ROOT+'/questionnaires/'+id, null, null, 'script');
                }
                else if(dtnode.data.isFolder)
                {
                    old_call = $.get(RAILS_ROOT+'/sections/'+dtnode.data.key, null, null, 'script');
                }
                else if(!(dtnode.data.isFolder))
                {
                    var key = (dtnode.data.key).toString().substring(1);
                    old_call = $.get(RAILS_ROOT+'/questions/'+key, null, null, 'script');
                }
            },
            initAjax: {
                url: RAILS_ROOT+'/questionnaires/'+id+'/tree/',
                dataType: "jsonp",
                data: { activate: nodeToActivate }
            }
        });
    }
}

//Update node info in the tree
function updateTreeNode(name)
{
    var tree = $("#tree").dynatree("getTree");
    var node = tree.getActiveNode();
    var new_name = "";
    if(name.length > 25)
        new_name = "...";
    node.data.title=name.substring(0,25)+ new_name;
    node.data.tooltip= name;
    node.render(false);
}
//add a new Section to the tree
function addNodeToTree(name, id, hasParent)
{
    var node;
    if(hasParent === "0")
        node = $("#tree").dynatree("getRoot");
    else
        node = $("#tree").dynatree("getActiveNode");
    var new_name = "";
    if(name.length > 25)
        new_name = "...";
    node.addChild({
        title: name.substring(0,25)+ new_name,
        tooltip: name,
        isFolder: true,
        activate: true,
        key: id,
        expand: true
    });
}

//updates the submission page of a user, with the links to the pdf files.
function updateUserSubmissionPage(user_id)
{
    setTimeout(function(){
        $("#questionnaires_for_submission").addClass("no_dialog");
        $.ajax({url: RAILS_ROOT+"/users/"+user_id+"/update_submission_page/", type: "get", dataType: "script"});
        $("#questionnaires_for_submission").removeClass("no_dialog");
        if( $("#questionnaires_for_submission.set_update_page").length > 0){
            updateUserSubmissionPage(user_id);
        }
    }, 60000);
}


function initialiseHideDisplayLangFields(){
    $("a.display_lang").livequery(function(){
        $(this).each(function(){
            $(this).click(function(e){
                e.preventDefault();
                if($("#fields_for_"+$(this).attr("id")).is(":visible"))
                {
                    $("#fields_for_"+$(this).attr("id")).slideUp("2000");
                    $(this).html($(this).html().replace("-","+"));
                }
                else
                {
                    $("#fields_for_"+$(this).attr("id")).slideDown("2000");
                    $(this).html($(this).html().replace("+","-"));
                }
            });
        });
    });
    $("a.show_all_lang_fields").livequery('click', function(e){
        e.preventDefault();
        $(this).parent().next().find('div.lang_fields').each(function(){
            $(this).slideDown("2000");
        });
        $(this).parent().find('a.display_lang, a.control_lang_display').each(function(){
            $(this).html($(this).html().replace("+","-"));
        });
    });
    $("a.hide_all_lang_fields").livequery('click', function(e){
        e.preventDefault();
        $(this).parent().next().find('div.lang_fields').each(function(){
            $(this).slideUp("2000");
        });
        $(this).parent().find('a.display_lang, a.control_lang_display').each(function(){
            $(this).html($(this).html().replace("-","+"));
        });
    });
}

function answerTypeGrid(columnNames, columnModel, the_data_stub, gridData, tableID, tableCaption, addButton, removeButton, mainAssociation, secondaryAssociation, updateSortIndex, attributeField){
    $("#"+tableID).jqGrid({
        data: gridData,
        datatype: "local",
        colNames: columnNames,
        colModel: columnModel,
        altRows: true,
        cellEdit: true,
        cellsubmit: 'clientArray',
        afterSaveCell: function(rowid, cellname, value, iRow, iCol){
            $("#answer_type_"+mainAssociation+"_attributes_"+rowid+"_"+secondaryAssociation+"_attributes_"+(iCol-(updateSortIndex ? 2 : 1))+"_"+attributeField).val(value);
        },
        editurl: "clientArray",
        multiselect: true,
        caption: tableCaption
    });

    $("#"+addButton).click(function(e){
        e.preventDefault();
        var template = $('#' + mainAssociation + '_fields_template').html();
        var regexp = new RegExp('new_' + mainAssociation, 'g');
        var new_id = new Date().getTime();
        //remove class "hide" from the required fields
        //the class is set to hide, to avoid the validator to try and validate the template
        $(this).parent().after(template.replace(regexp, new_id));
        //var current_id = $("#options_list").jqGrid('getGridParam', "records");
        the_data_stub[0].id = new_id;
        if(updateSortIndex)
        {
            var totalRecords = $("#"+tableID).jqGrid("getGridParam", "records");
            the_data_stub[0].Index = totalRecords;
            $("#answer_type_"+mainAssociation+"_attributes_"+new_id+"_sort_index").val(totalRecords);
        }
        $("#"+tableID).jqGrid('addRowData', "id", the_data_stub );
        //$("#options_list").trigger('reloadGrid');
    });

    $("#"+removeButton).click(function(e){
        e.preventDefault();
        var s = $("#"+tableID).jqGrid('getGridParam', 'selarrrow');
        for(var i = (s.length-1); i>=0; i--)
        {
            $("#answer_type_"+mainAssociation+"_attributes_"+s[i]+"__destroy").val("1");
            $("#"+tableID).jqGrid('delRowData', s[i]);
        }
        if(updateSortIndex)
        {
            var remaining_objects = $("#"+tableID).jqGrid('getDataIDs');
            for(i = (remaining_objects.length-1); i>=0; i--)
            {
                var the_index = $("#"+tableID).jqGrid("getInd", remaining_objects[i])-1;
                var row = $("#"+tableID).jqGrid('getRowData', remaining_objects[i]);
                if(row.Index != the_index )
                {
                    row.Index = the_index;
                    $("#"+tableID).jqGrid('setRowData', remaining_objects[i], row);
                    $("#answer_type_"+mainAssociation+"_attributes_"+remaining_objects[i]+"_sort_index").val(the_index);
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
        $.post(this.action, $(this).serialize(), null, "script");
        return false;
    });

    return this;
};
/*
 Retreive a page with get
 Use the class get in your link declaration
 <%= link_to 'My link', my_path(),:class => "get" %>
 */

jQuery.fn.getWithAjax = function() {
    this.unbind('click', false);
    this.click(function() {
        $.get($(this).attr("href"), $(this).serialize(), null, "script");
        return false;
    });
    return this;
};
/*
 Post data via html
 Use the class post in your link declaration
 <%= link_to 'My link', my_new_path(),:class => "post" %>
 */

jQuery.fn.postWithAjax = function() {
    this.unbind('click', false);
    this.click(function() {
        $.post($(this).attr("href"), $(this).serialize(), null, "script");
        return false;
    });
    return this;
};
/*
 Update/Put data via html
 Use the class put in your link declaration
 <%= link_to 'My link', my_update_path(data),:class => "put",:method => :put %>
 */

jQuery.fn.putWithAjax = function() {
    this.unbind('click', false);
    this.click(function() {
        $.put($(this).attr("href"), $(this).serialize(), null, "script");
        return false;
    });
    return this;
};
/*
 Delete data
 Use the class delete in your link declaration
 <%= link_to 'My link', my_destroy_path(data),:class => "delete",:method => :delete %>
 */

jQuery.fn.deleteWithAjax = function() {
    this.removeAttr('onclick');
    this.unbind('click', false);
    this.click(function() {
        $.delete_($(this).attr("href"), $(this).serialize(), null, "script");
        return false;
    });
    return this;
};
