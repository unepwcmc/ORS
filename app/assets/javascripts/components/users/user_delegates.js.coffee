window.UsersComponent.UserDelegates = class UsersComponent.UserDelegates
  @initialize: ->
    @addEventListeners()

  @addEventListeners: ->
    @showDetails()
    @delegatedTasksTable()

  @showDetails: ->
    $(".show-details").click( (e) ->
      e.preventDefault()
      $(@).parent().siblings('.delegation-details').toggle('slow')
    )

  @delegatedTasksTable: ->
    $("#delegated_tasks_table").tablesorter({
      sortList: [[0,0]],
      widgets: ['zebra']
    })


