window.QuestionnairesComponent.IndexPage = class QuestionnairesComponent.IndexPage
  TABLE_SORTER_OPTS =
    sortList: [4, 1]
    widgets: ['zebra']
    headers: {5: {sorter: false}}

  @initialize: ->
    $el = $('#questionnaires_index')

    if($el.length?)
      instance = new QuestionnairesComponent.IndexPage($el)
      instance.initializeTablesorter()

  constructor: (@$el) ->
    @$pagerEl = $('#pager_div')

  initializeTablesorter: ->
    @$el.tablesorter(
      sortList: [TABLE_SORTER_OPTS.sortList],
      widgets: TABLE_SORTER_OPTS.widgets,
      headers: TABLE_SORTER_OPTS.headers
    )
    @$el.tablesorterPager(container: @$pagerEl)

