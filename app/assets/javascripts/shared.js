jQuery.ajaxSetup({ 'beforeSend': function(xhr) {xhr.setRequestHeader("Accept", "text/javascript");} });

function _ajax_request(url, data, callback, type, method) {
  if (jQuery.isFunction(data)) {
    callback = data;
    data = {};
  }
  return jQuery.ajax({
    type: method,
    url: url,
    data: data,
    success: callback,
    dataType: type
  });
}

jQuery.extend({
  put: function(url, data, callback, type) {
    return _ajax_request(url, data, callback, type, 'PUT');
  },
  delete_: function(url, data, callback, type) {
    return _ajax_request(url, data, callback, type, 'DELETE');
  }
});

function formValidation(){

  $.metadata.setType("attr", "validate");

  $("#generator_form").livequery(function(){
    $(this).validate({
      errorContainer:$("div.error_container"),
      errorLabelContainer: $("ul#error_messages",$("div#error_container")),
      wrapper: "li",
      errorClass: "inline-errors",
      ignore: ".hide",
      submitHandler: function(form) {
        if($("form.normal").length === 0)
          $.post(form.action, $(form).serialize(), null, "script");
        else
          form.submit();
      }
    });
  });
}

function initializeToolTips(){
  $(".obj_tooltip, .li_tooltip").livequery(function(){
    $(this).each(function(){
      $(this).tooltipster({
        contentAsHTML: true,
        maxWidth: 300,
        theme: 'tooltipster-light'
      });
    })
  })
}

function hideFlashMessages(){
  if(('#flash_notice').length > 0)
    setTimeout(function(){
      $("#flash_notice").fadeOut(500,
        function(){
          $("#flash_notice").remove()})},
      1400);
  if(('#flash_error').length > 0)
    setTimeout(function(){
      $("#flash_error").fadeOut(500,
        function(){
          $("#flash_error").remove()})},
      1400);
}

// Show the flash message and then hide the div
function flash_message(name, msg){
  $.gritter.add({
    title: name,
    text: msg,
    class_name: "gritter_flash flash_"+name
  });
}

/*
 Ajaxify all the links on the page.
 This function is called when the page is loaded. You'll probably need to call it again when you write render new datas that need to be ajaxyfied.'
 */

function ajaxLinks(){

  $('.ajaxForm').livequery(function(){
    $(this).unbind('submit');
    $(this).submit(function() {
      $.post(this.action, $(this).serialize(), null, "script");
      return false;
    });

    return this;
  });

  $('a.get').livequery(function(){
    $(this).unbind('click');
    $(this).click(function() {
      $.get($(this).attr("href"), $(this).serialize(), null, "script");
      return false;
    });
    return this;
  });

  $('a.post').livequery(function(){
    $(this).unbind('click');
    $(this).click(function() {
      $.post($(this).attr("href"), $(this).serialize(), null, "script");
      return false;
    });
    return this;
  });

  $('a.put').livequery(function(){
    $(this).unbind('click');
    $(this).click(function() {
      $.put($(this).attr("href"), $(this).serialize(), null, "script");
      return false;
    });
    return this;
  });

  $('a.delete').livequery(function(){
    $(this).removeAttr('onclick');
    $(this).unbind('click');
    $(this).click(function() {
      var del = true;
      if($(this).hasClass('confirm_deletion'))
        del = confirm($(this).attr("confirm_text"));
      if(del)
        $.delete_($(this).attr("href"), $(this).serialize(), null, "script");
      return false;
    });
    return this;
  });
}

function handleInfoDisplayGeneratorShowPages(){
  $("a.hide_info").livequery(function(){
    $(this).each(function(){
      $(this).click(function(e){
        e.preventDefault();
        // div.info_header > div.holding_the_buttons > p > a.hide_info
        $(this).parents('div.info_header').next('div').slideUp("2000", function(){
          $(this).prev('div').css("border-bottom-width","1px");
        });
        $(this).siblings(".show_info").show();
        $(this).siblings(".save_button").hide();
        $(this).hide();
      });
    });
  });
  $("a.show_info").livequery(function(){
    $(this).each(function(){
      $(this).click(function(e){
        e.preventDefault();
        $(this).parents('div.info_header').css("border-bottom-width", "0");
        $(this).parents('div.info_header').next('div').slideDown("2000");
        $(this).siblings(".hide_info").show();
        $(this).siblings(".save_button").show();
        $(this).hide();
      })
    });
  });
}

function initialiseExtraFieldsHandlers(){
  $('form a.remove_child').livequery('click', function(e){
    e.preventDefault();
    var hidden_field = $(this).prev("input[type='hidden']")[0];
    if(hidden_field)
    {
      hidden_field.value = '1';
    }
        $(this).parents("div.option").slideUp("2000");//.addClass('hide');//.removeClass('required');//hide('slow');
        $(this).parents("div.option").find(".option_text").each(function(){
          //addClass hide to the required fields being hid
          //so that the validator ignores them.
          $(this).addClass('hide');
        });
        return false;
      });
  $('form a.add_child').livequery('click',function(e){
    e.preventDefault();
    var association = $(this).attr('data-association');
    var template = $('#' + association + '_fields_template').html();
    var regexp = new RegExp('new_' + association, 'g');
    var new_id = new Date().getTime();
      //remove class "hide" from the required fields
      //the class is set to hide, to avoid the validator to try and validate the template
      while(template.search("option_text hide") != -1)
        template = template.replace("option_text hide", "option_text");
      $(this).parent().before(template.replace(regexp, new_id));
      return false;
    });
  $("#answer_other_required").on('change', null, function(){
    if($("#answer_other_required").is(':checked'))
    {
      $("#other_fields").show();
    }
    else
    {
      $("#other_fields").hide();
      $("#answer_other_text").val('');
      $("#answer_other_help_text").val('');
    }
  });
}
