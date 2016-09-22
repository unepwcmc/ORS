window.UsersComponent = class UsersComponent
  @initialize: ->
    @addEventListeners()

  @addEventListeners: ->
    @userDetailsTooltip()

  @userDetailsTooltip: ->
    tooltipClass = '.information-tooltip'
    $("#{tooltipClass}-trigger").toggle( (ev) ->
      ev.preventDefault()
      $("#{tooltipClass}-trigger").not(@).siblings(tooltipClass).hide()
      $(@).html('<i class="fa fa-close"></i> close')
      $(@).siblings(tooltipClass).show()
    , (ev) ->
      ev.preventDefault()
      $(@).html('<i class="fa fa-align-left"></i> details')
      $(@).siblings(tooltipClass).hide()
    )

$(document).ready -> UsersComponent.initialize()
