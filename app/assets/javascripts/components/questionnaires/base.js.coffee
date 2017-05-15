window.QuestionnairesComponent = class QuestionnairesComponent
  @initialize: ->
    QuestionnairesComponent.IndexPage.initialize()
    QuestionnairesComponent.NewPage.initialize()

    @addEventListeners()

  @addEventListeners: ->
    @hideInfoContent()
    @addCloseEvent()
    @addHideInfoEvent()
    @slideDuplicateQuestionnaire()

  @hideInfoContent: ->
    $('.app-content').on('click', '.info-toggle-header', (ev) ->
      ev.preventDefault()
      $(@)
        .siblings('.info-content')
        .slideToggle()

      $(@)
        .find('i.fa')
        .toggleClass('fa-angle-up fa-angle-down')

      toggle_info = $(@).find('.toggle-info')
      if toggle_info.text().indexOf("Hide") != -1
        toggle_info.text("Show")
      else
        toggle_info.text("Hide")
    )

  @addHideInfoEvent: ->
    $('.app-content').on('header:hide', '.info-toggle-header', (ev) ->
      ev.preventDefault()
      $(@).closest('div.language').slideUp()
      $(@).closest('div.extra-info-container').slideUp()
    )

  @addCloseEvent: ->
    $('.app-content').on('header:close', '.info-toggle-header', (ev) ->
      ev.preventDefault()
      $(@)
        .siblings('.info-content')
        .slideUp()

      $(@)
        .find('i.fa')
        .removeClass('fa-angle-up')
        .addClass('fa-angle-down')

      toggle_info = $(@).find('.toggle-info')
      if toggle_info.text().indexOf("Hide") != 1
        toggle_info.text("Show")
    )

  @slideDuplicateQuestionnaire: ->
    $("#questionnaire_original_id").change( ->
        val = $(@).val()
        closedAny = false
        $(".questionnaires_info").each( ->
          if($(@).is(":visible"))
            $(@).slideUp("slow", ->
              $("#questionnaire_"+val).slideDown("slow")
            )
            closedAny = true
        )
        if(!closedAny)
          $("#questionnaire_"+val).slideDown("slow")
    )


$(document).ready -> QuestionnairesComponent.initialize()

