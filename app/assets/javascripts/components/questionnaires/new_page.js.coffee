window.QuestionnairesComponent.NewPage = class QuestionnairesComponent.NewPage
  TOGGLE_DURATION = 300

  @initialize: ->
    FormValidator.initialize($('#generator_form'))

    instance = new QuestionnairesComponent.NewPage()
    instance.initializePageEls()

  constructor: (@$el) ->

  initializePageEls: ->
    @initializeMoreLanguagesSwitches()
    @initializeLanguagesInclusion()
    @initializeMainLanguageSwitch()

  initializeMoreLanguagesSwitches: ->
    $moreLanguagesEl = $("#more_languages")
    $addLanguagesEl = $(".add_languages_buttons")

    toggleButtons = (ev) ->
      ev.preventDefault()
      $moreLanguagesEl.toggle(TOGGLE_DURATION)
      $addLanguagesEl.toggle()

    $("#show_more_languages").click(toggleButtons)

    $("#hide_more_languages").click( (ev) ->
      toggleButtons(ev)

      $(".include_check_box").each( ->
        $(@).attr('checked', false)
        destroyField = $(@).siblings(".destroy-hidden-field")
        destroyField.value = '1' # set to destroy
      )
    )

  ## when an "include_check_box" is clicked the value of the hidden "_destroy"
  ## field is set to 0 so that the language is added to the new questionnaire
  ## the default of the hidden "_destroy" field is 1, because it is assumed
  ## that the user won't want those languages
  initializeLanguagesInclusion: ->
    $('.include_check_box').change( ->
      console.log(@)
      destroyField = $(@).siblings(".destroy-hidden-field")[0]

      if($(@).is(':checked'))
        destroyField.value = '0'
      else
        destroyField.value = '1'
    )

  ## when the main language is selected the "extra language" field that matches
  ## will be disabled, because there can only # be one input of each language.
  initializeMainLanguageSwitch: ->
    $('#questionnaire_questionnaire_fields_attributes_0_language').change( ->
      value = $(@).val()

      # starts by enabling all of the extra-languages inputs
      $('.extra_lang_div textarea').attr('disabled', false)
      $('.extra_lang_div').children().css('background-color', '#ffffff')
      $('.include_check_box').attr('disabled', false)

      if(value != '')
        $fieldValue = $('#field_'+value)
        $includeValue = $('#include_'+value)

        # disable the one that matches the selected value
        $fieldValue.find('textarea').attr('disabled', true)
        $fieldValue.children().css('background-color', '#dddddd')

        $includeValue.attr('checked',false).attr('disabled',true)
          .siblings(".destroy-hidden-field")[0].value = '1'

      # change the title text_field text direction to "right-to-left" when the
      # selected language is arabic
      $thisParents = $(@).parents('#default_language')

      if(value == 'ar')
        $thisParents.find('textarea').attr('dir', 'rtl')
        $thisParents.find('input').attr('dir', 'rtl')
      else
        $thisParents.find('textarea').attr('dir', 'ltr')
        $thisParents.find('input').attr('dir', 'ltr')
    )
