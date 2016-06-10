function customResizeSelected()
{
    if ($("#resizeany").is(":checked")) {
        $("#resizex").prop("disabled", false);
        $("#resizey").prop("disabled", false);
    } else {
        $("#resizex").prop("disabled", true);
        $("#resizey").prop("disabled", true);
    }
}
