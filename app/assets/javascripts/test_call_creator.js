$(function() {

    function createTestCallDestinationOptions() {
        var optionHtml = '';
        _.each(window.test_call_creator_options, function(key, value) {
            optionHtml += '<option value="' + value + '">' + key + '</option>';
        });
        return optionHtml;
    }

    $('#test-call-creator').on('click',function() {
        var now = new Date().toLocaleString();
        var optionHtml = createTestCallDestinationOptions();

        bootbox.dialog({
            title: 'Create callback task',
            message: '<form><fieldset class="form-group">' +
            '<div class="row"><label for="test-call-creator-calltime" class="col-xs-3 control-label">Calltime</label><div class="input-group col-xs-9"><input class="form-control" type="text" id="test-call-creator-calltime" value="'+now+'"/></div></div>' +
            '<div class="row"><label for="test-call-creator-callerid" class="col-xs-3 control-label">From</label><div class="input-group col-xs-9"><input class="form-control" type="text" id="test-call-creator-callerid"/></div></div>' +
            '<div class="row"><label for="test-call-creator-extension" class="col-xs-3 control-label">To</label><div class="input-group col-xs-9"><input class="form-control" type="tel" id="test-call-creator-extension" value="+Unavailable"/></div></div>' +
            '<div class="row"><label for="test-call-creator-ivrchoise" class="col-xs-3 control-label">Ivrchoise ?</label><div class="input-group col-xs-9"><input class="form-control" type="text" id="test-call-creator-ivrchoise" value="111"/></div></div>' +
            '<div class="row"><label for="test-call-creator-destination" class="col-xs-3 control-label">MediaChannel ID</label><div class="input-group col-xs-9"><select class="form-control" type="text" id="test-call-creator-destination"> ' + optionHtml + ' </select></div></div>' +
            '</fieldset></form>'
            ,
            buttons: {
                success: {
                    label: 'Create task',
                    className: 'btn btn-default',
                    callback: function() {
                        /*var message = '<calldata>' +
                            '<calltime>' + $('#test-call-creator-calltime').val() + '</calltime>' +
                            '<callerid>' + $('#test-call-creator-callerid').val() + '</callerid>' +
                            '<extension>' + $('#test-call-creator-extension').val() + '</extension>' +
                            '<ivrchoise>' + $('#test-call-creator-ivrchoise').val() + '</ivrchoise>' +
                            '<destination>' + $('#test-call-creator-destination').val() + '</destination>' +
                            '</calldata>';
                        */
                        var message = {};
                        message.callid = "asdfasdfasdf";
                        message.channel = "SIP/asdfasdf-asdfasdf";
                        message.variables = {};
                        message.variables.datetime = $('#test-call-creator-calltime').val();
                        message.variables.callerid = $('#test-call-creator-callerid').val();
                        message.variables.extension = $('#test-call-creator-extension').val();

                        $.ajax('/call_detail_records/json', {
                            data: JSON.stringify(message),
                            type: 'POST',
                            contentType: 'application/json'
                        });
                    }
                }
            }
        });

    });

});


/*
 <calldata>
 <calltime>30.09.2014 15:08:52</calltime>
 <callerid></callerid>
 <extension>+358985646803</extension>
 <ivrchoise>2</ivrchoise>
 <destination>258985646803</destination>
 </calldata>


 */
