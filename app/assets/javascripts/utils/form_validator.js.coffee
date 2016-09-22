window.FormValidator = class FormValidator
  @initialize: ($el) ->
    instance = new FormValidator($el)
    instance.attachValidation()

  constructor: (@$el) ->

  attachValidation: ->
    $.metadata.setType("attr", "validate")

    @$el.livequery( ->
      $(@).validate(
        errorContainer: $(".error_container"),
        wrapper: "li",
        errorClass: "inline-errors",
        ignore: ".hide",
        submitHandler: (form) ->
          if($("form.normal").length == 0)
            $.post(form.action, $(form).serialize(), null, "script")
          else
            form.submit()
      )
    )
