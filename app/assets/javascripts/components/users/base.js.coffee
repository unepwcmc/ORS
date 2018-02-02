window.UsersComponent = class UsersComponent
  @initialize: ->
    @addEventListeners()

  @addEventListeners: ->
    @userDetailsTooltip()
    @respondentsTable()
    @rolesRestriction()
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

  @respondentsTable: ->
    table = $('.respondents-list')
    table.slideDown() if @delegateBoxChecked()
    that = @
    $('.delegate-box, .super_delegate-box').on('click', ->
      if $(@).attr('checked') || that.delegateBoxChecked()
        table.slideDown()
      else
        table.slideUp()
    )

  @delegateBoxChecked: ->
    $('.delegate-box').attr('checked') || $('.super_delegate-box').attr('checked')

  @rolesRestriction: ->
    delegate_box = $('.delegate-box')
    $('.super_delegate-box').on('change', ->
      if $(this).attr('checked')
        delegate_box.attr('checked', false)
        delegate_box.attr('disabled', true)
      else
        delegate_box.attr('disabled', false)
    )
    respondent_admin_box = $('.respondent_admin-box')
    $('.admin-box').on('change', ->
      if $(this).attr('checked')
        respondent_admin_box.attr('checked', false)
        respondent_admin_box.attr('disabled', true)
      else
        respondent_admin_box.attr('disabled', false)
    )


$(document).ready -> UsersComponent.initialize()
