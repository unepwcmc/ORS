window.LoopSourcesComponent = class LoopSourcesComponent
  @initialize: ->
    @addEventListeners()

  @addEventListeners: ->
    @updateSource()

  @updateSource: ->
    $("#update_source").click( (e) ->
      e.preventDefault()
      $("#edit_source").toggle('slow')
    )

$(document).ready -> LoopSourcesComponent.initialize()
