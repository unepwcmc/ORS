window.Layout = class Layout
  @initialize: ->
    @addEventListeners()

  @addEventListeners: ->
    $("#display_language").change( ->
      selected_lang = $(@).val()
      if(selected_lang != "")
        window.location = "?lang=#{selected_lang}"
    )

$(document).ready -> Layout.initialize()
