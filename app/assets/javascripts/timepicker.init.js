$(function() {
    var defaultOpts = {
        showMeridian: false,
        defaultTime: false,
        showInputs: false,
        disableFocus: true
    };
    function getInputs(changedInput) {
        var startChanged = changedInput.hasClass('start-time'),
            otherClass = startChanged ? 'end-time' : 'start-time',
            otherInput = changedInput.closest('.bootstrap-timepicker').parent().find('.timepicker.' + otherClass);

            return startChanged ? { start: changedInput, end: otherInput, startChanged: startChanged } : { start: otherInput, end: changedInput, startChanged: startChanged }
    }
    $('.timepicker').timepicker(defaultOpts)
        .on('changeTime.timepicker', function(e) {
            var inputs = getInputs($(e.currentTarget)),
                startTime,
                endTime;
            if(inputs.start.val() == "" || inputs.end.val() == "") {
                return;
            }
            if(inputs.startChanged) {
                startTime = moment(e.time.value, 'hh:mm');
                endTime = moment(inputs.end.val(), 'hh:mm');
            } else {
                startTime = moment(inputs.start.val(), 'hh:mm');
                endTime = moment(e.time.value, 'hh:mm');
            }
            if(endTime.isBefore(startTime)) {
                if(inputs.startChanged) {
                    inputs.end.timepicker('setTime', e.time.value);
                } else {
                    inputs.start.timepicker('setTime', e.time.value);
                }
            }
        })
        .on('show.timepicker', function (e) {
            var inputs = getInputs($(e.currentTarget));
            if(inputs.start.val() == "" && inputs.end.val() == "") {
                inputs.start.timepicker('setTime' ,'08:00');
                inputs.end.timepicker('setTime', '16:00');
            }
        });

});
