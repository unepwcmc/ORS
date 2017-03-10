jQuery.ajaxSetup({'beforeSend': function(xhr) {xhr.setRequestHeader("Accept", "text/javascript");}});

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

function initializeToolTips() {
  $(".obj_tooltip, .li_tooltip").livequery(function() {
    $(this).each(function() {
      $(this).tooltipster({
        contentAsHTML: true,
        maxWidth: 300,
        theme: 'tooltipster-light'
      });
    })
  })
}

function hideFlashMessages() {
  var flashes = [$('#flash_notice'), $('#flash_error')];
  var fadeOutAndRemove = function(flash) {
    if(flash.length > 0) {
      setTimeout(function() {
        flash.fadeOut(500, flash.remove);
      }, 1400);
    }
  };

  flashes.forEach(fadeOutAndRemove);
}

// Show the flash message and then hide the div
function flash_message(name, msg) {
  $.gritter.add({
    title: name,
    text: msg,
    class_name: 'gritter_flash flash_'+name
  });
}

/*
 Ajaxify all the links on the page.
 This function is called when the page is loaded. You'll probably need to call
 it again when you write render new datas that need to be ajaxyfied.
*/
function ajaxLinks() {
  $('.ajaxForm').livequery(function() {
    var $el = $(this);

    $el.unbind('submit');
    $el.submit(function() {
      $.post(this.action, $el.serialize(), null, "script");
      return false;
    });

    return this;
  });

  var ajaxifyDelete = function() {
    var $el = $(this);

    $el.removeAttr('onclick');
    $el.unbind('click');
    $el.click(function() {
      var del = true;
      if($el.hasClass('confirm_deletion')) {
        del = confirm($el.attr("confirm_text"));
      }
      if(del) {
        $.delete_($el.attr("href"), $el.serialize(), null, "script");
      }

      return false;
    });

    return this;
  };

  var ajaxifyWithMethod = function(method) {
    return function() {
      var $el = $(this);

      //unbind only if it's not the pivot-table-regenerate button
      //this is to prevent something unespected happening with removing
      //the unbind click for all elements
      if(!$el.hasClass('pivot-table-regenerate')) {
        $el.unbind('click');
      }

      $el.click(function() {
        method($el.attr("href"), $el.serialize(), null, "script");
        return false;
      });

      return this;
    }
  };

  $('a.get').livequery(ajaxifyWithMethod($.get));
  $('a.post').livequery(ajaxifyWithMethod($.post));
  $('a.put').livequery(ajaxifyWithMethod($.put));
  $('a.delete').livequery(ajaxifyDelete);
}

function handleInfoDisplayGeneratorShowPages() {
  $('li.hide_info').livequery(function() {
    $(this).each(function() {
      var $el = $(this);

      $el.click(function(e) {
        e.preventDefault();

        // div.info_header > div.holding_the_buttons > p > a.hide_info
        $el.parents('div.info_header').next('div').slideUp('2000', function() {
          $(this).prev('div').css('border-bottom-width','1px');
        });

        $el.siblings('.save_button').hide();
        $el.css('display', 'none');
        $el.siblings('.show_info').css('display', 'inline-block');
      });
    });
  });

  $('li.show_info').livequery(function() {
    $(this).each(function() {
      var $el = $(this);
      $el.click(function(e) {
        e.preventDefault();

        $el.parents('div.info_header').css('border-bottom-width', '0');
        $el.parents('div.info_header').next('div').slideDown('2000');
        $el.siblings('.save_button').show();
        $el.siblings('.hide_info').css('display', 'inline-block');
        $el.css('display', 'none');
      });
    });
  });
}

function initialiseExtraFieldsHandlers() {
  $('form a.remove_child').livequery('click', function(e) {
    e.preventDefault();

    var hidden_field = $(this).prev("input[type='hidden']")[0];
    if(hidden_field) {
      hidden_field.value = '1';
    }

    $(this).parents("div.option").slideUp("2000");
    $(this).parents("div.option").find(".option_text").each(function() {
      //addClass hide to the required fields being hid
      //so that the validator ignores them.
      $(this).addClass('hide');
    });
    return false;
  });

  $('form a.add_child').livequery('click',function(e) {
    e.preventDefault();

    var association = $(this).attr('data-association');
    var template = $('#' + association + '_fields_template').html();
    var regexp = new RegExp('new_' + association, 'g');
    var new_id = new Date().getTime();

    //remove class "hide" from the required fields
    //the class is set to hide, to avoid the validator to try and validate the template
    while(template.search('option_text hide') != -1) {
      template = template.replace('option_text hide', 'option_text');
    }

    $(this).parent().before(template.replace(regexp, new_id));
    return false;
  });

  $('#answer_other_required').on('change', null, function() {
    if($('#answer_other_required').is(':checked')) {
      $('#other_fields').show();
    } else {
      $('#other_fields').hide();
      $('#answer_other_text').val('');
      $('#answer_other_help_text').val('');
    }
  });
}

function initialiseSelectAll(){
  $('.select-all-checkbox').click(function(){
    var table= $(this).closest('table');

    if($(this).prop('checked')){
      $('td input:checkbox',table).prop('checked', true);
    } else {
      $('td input:checkbox',table).prop('checked', false);
    }
  });
}

function initialiseAuthorizedFilter(){
  $('#authorized_filter').on('change',function(){
    var selectedValue = $(this).val();
    filter('tbody tr', selectedValue);
    //$('#myTable').fnFilter(selectedValue, 1); //Exact value, column, reg
  });
}
