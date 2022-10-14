$(function() {
    $('input[type="checkbox"].toggle-schedule-entries').on('click', function() {
        var toggler = $(this);
        toggler.closest('table')
            .find('tbody td:nth-child(' + (parseInt(toggler.closest('thead').find('input[type="checkbox"].toggle-schedule-entries').index(toggler)) + 1) +')')
            .find('.timepicker')
            .prop('disabled', !toggler.is(':checked'))
            .end()
            .find('.destroy-schedule-entry')
            .val(!toggler.is(':checked') ? 1 : 0)
    })
});