define(["jquery", "durandal/composition"], function($, composition) {
    var handlers = {
        // Just use knockout's "event" binding, this is just for example:
        //
        //"hiddenBsModal": {
        //    init: function (element, valueAccessor) {
        //        var eventHandler = valueAccessor();  //What do you want to do with this value?
        //        $(element).on("hidden.bs.modal", eventHandler);
        //    }
        //}
        //
        // Usage: <div id="my-modal" class="modal fade" data-bind="hiddenBsModal: onMyModalHidden">

        // TODO: Add any custom binding handlers here. This module should already be required by main.js.
    };

    $.each(handlers, function(name, handler) {
        composition.addBindingHandler(name, handler);
    });

    return handlers;
});