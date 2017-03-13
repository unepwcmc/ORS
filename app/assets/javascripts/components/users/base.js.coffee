window.UsersComponent = class UsersComponent
  @initialize: ->
    @addEventListeners()

  @addEventListeners: ->
    @userDetailsTooltip()

  @userDetailsTooltip: ->
    tooltipClass = '.information-tooltip'
    $(document).on('click', "#{tooltipClass}-trigger", (ev) ->
      ev.preventDefault()
      if ($(@).find('.fa-align-left').length)
        $("#{tooltipClass}-trigger").not(@).siblings(tooltipClass).hide()
        $("#{tooltipClass}-trigger").not(@).html('<i class="fa fa-align-left"></i> details')
        $(@).html('<i class="fa fa-close"></i> close')
        $(@).siblings(tooltipClass).show()
      else
        $(@).html('<i class="fa fa-align-left"></i> details')
        $(@).siblings(tooltipClass).hide()
    )

$(document).ready -> UsersComponent.initialize()
