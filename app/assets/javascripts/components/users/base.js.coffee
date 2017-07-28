window.UsersComponent = class UsersComponent
  @initialize: ->
    @addEventListeners()

  @addEventListeners: ->
    @userDetailsTooltip()
    #Enables search through users table
    enableSearch()

  @userDetailsTooltip: ->
    tooltipClass = '.information-tooltip'
    $(document).on('click', "#{tooltipClass}-trigger", (ev) ->
      ev.preventDefault()
      $this = $(@)
      if ($this.find('.fa-align-left').length)
        $("#{tooltipClass}-trigger").not(@).siblings(tooltipClass).hide()
        $("#{tooltipClass}-trigger").not(@).html('<i class="fa fa-align-left"></i> details')
        $this.html('<i class="fa fa-close"></i> close')
        $this.siblings(tooltipClass).show()
      else
        $this.html('<i class="fa fa-align-left"></i> details')
        $this.siblings(tooltipClass).hide()
    )

$(document).ready -> UsersComponent.initialize()
