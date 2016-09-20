$(document).ready(function(){
  var container = $(document);

  container.on("scroll", function(e) {

    if (container.scrollTop() >= 323) {
      $(".sticky-toolbar").addClass("fixed");
      $("#questionnaire").css("padding-top", "65px");
    } else {
      $(".sticky-toolbar").removeClass("fixed");
      $("#questionnaire").css("padding-top", "0px");
    }

  });
});

