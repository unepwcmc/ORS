window.LoopItemsComponent = class LoopItemsComponent
  @initialize: ->
    @addEventListeners()

  @addEventListeners: ->
    @itemNamesTable()

  @itemNamesTable: ->
    $("#item_names_table").on("click","#add_item_name_other_languages", (e) ->
        e.preventDefault()
        $("#add_extra").hide('slow').empty()
        $("#add_extra_source").hide('slow').empty()
        $("#add_loop_item_names_source").show('slow')
    )
    $("#hide_add_translations").click( (e) ->
        e.preventDefault()
        $("#add_loop_item_names_source").hide('slow')
    )
    $("#item_names_table").tablesorter({
        sortList: [[0,0]],
        widgets: ['zebra']
    })

$(document).ready -> LoopItemsComponent.initialize()
