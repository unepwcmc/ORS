window.QuestionnairesComponent.DashboardPage = class QuestionnairesComponent.DashboardPage

  @initialize: ->
    @addEventListeners()

  @addEventListeners: ->
    @pivotTableEvents()

  @pivotTableEvents: ->
    $('.pivot-table-regenerate').on('click', ->
      $('.pivot-table-loading').show()
    )
