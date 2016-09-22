window.QuestionnaireHandler = {
  initialiseSections: function($sectionContainer, $contentContainer) {
    var insertIntoContainer = function(data) { $contentContainer.html(data); };

    $sectionContainer.find('.section-link').click(function(ev) {
      $el = $(this);

      $.get($el.attr('href'), insertIntoContainer);
      ev.preventDefault();
    });
  }
};
