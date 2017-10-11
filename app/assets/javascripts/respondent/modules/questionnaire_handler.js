window.QuestionnaireHandler = {
  initialiseSections: function($sectionContainer, $contentContainer) {
    var insertIntoContainer = function(data) { $contentContainer.html(data); };

    $sectionContainer.find('.section-link').click(function(ev) {
      $el = $(this);

      $.ajax({
        url: $el.attr('href'),
        type: 'GET',
        success: insertIntoContainer,
        error: function(jqXHR, textStatus, errorThrown ){
          console.log("jqXHR = "+JSON.stringify(jqXHR));
          console.log("textStatus = "+JSON.stringify(textStatus));
          console.log("errorThrown = "+JSON.stringify(errorThrown));
        }
      })
      ev.preventDefault();
    });
  }
};
