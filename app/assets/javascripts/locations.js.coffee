$ ->
  $("input.check-all").change ->
    $("input[name='location_ids[]']").prop("checked", $(this).prop("checked"))

  $(".delete-location").click (e) ->
    $(this).closest("tr").find("input[name='location_ids[]']").prop("checked", true)
    return true

  $("#save-update-defaults").click (e) ->
    e.preventDefault()

    link = $(this)

    method = $("input[name='_method']")
    method.prop("value", "put")

    form = $(link).closest("form")
    form.prop("action", link.prop("href"))
    form.submit()

  EditTable.build "#edit_addresses"
