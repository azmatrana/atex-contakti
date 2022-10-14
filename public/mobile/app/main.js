requirejs.config({
  paths: {
    "text": "../bower_components/requirejs-text/text",
    "durandal": "../bower_components/durandal/js",
    "plugins": "../bower_components/durandal/js/plugins",
    "transitions": "../bower_components/durandal/js/transitions",
    "knockout": "../bower_components/knockout/dist/knockout",
    "bootstrap": "../bower_components/bootstrap/js",
    "pickadate": "../bower_components/pickadate/lib/compressed/picker",
    "pickadate-date": "../bower_components/pickadate/lib/compressed/picker.date",
    "tokenfield": "../bower_components/bootstrap-tokenfield/js/bootstrap-tokenfield",
    "select2": "../bower_components/select2/select2.min",
    "jquery": "../bower_components/jquery/dist/jquery",
    "jquery-ui": "../bower_components/jquery-ui/jquery-ui.min",
    "i18next": "../bower_components/i18next/i18next.amd.withJQuery",
    "moment": "../bower_components/moment/moment-with-locales",
    "faye": "../bower_components/faye/include",
    "bootstrap-fileupload": "../bower_components/bootstrap-fileupload/bootstrap-fileupload"
  },
  shim: {
    "bootstrap": {
      deps: ["jquery", "jquery-ui"],
      exports: "jQuery"
    },
    "bootstrap-fileupload": {
      deps: ["jquery", "jquery-ui"],
      exports: "jQuery"
    },
    "danthes": {
      deps: ["faye"],
      exports: "Danthes"
    }
  }
});

define([
  "durandal/system",
  "durandal/app",
  "durandal/viewLocator",
  "durandal/binder",
  "jquery",
  "jquery-ui",
  "i18next",
  "moment",
  "binding_handlers",
  "pickadate",
  "bootstrap-fileupload",
], function (system, app, viewLocator, binder, $, jqui, i18n, moment, bootstrapFileupload) {
  // Hackish solution to ensure pickadate is loaded before the date extension
  require(["pickadate-date"], function (dp) {
    //>>excludeStart("build", false);
    system.debug(true);
    //>>excludeEnd("build");

    var browser_language  = navigator.languages && navigator.languages[0] || navigator.language || navigator.userLanguage;

    cname = "test_cookies";
    var name = cname + "=";
    var ca = document.cookie.split(';');
    var cvalue  = ""
    for(var i = 0; i < ca.length; i++) {
      var c = ca[i];
      while (c.charAt(0) == ' ') {
        c = c.substring(1);
      }
      if (c.indexOf(name) == 0) {
        cvalue = c.substring(name.length, c.length);
        break;
      }
    }
    console.log("browser_language = ", browser_language)

    if(['en', 'fi'].includes(browser_language)){
      if(cvalue && cvalue === false) {
        i18n.setLng(browser_language)
        document.cookie = "test_cookies=true; path=/; max-age=31536000";
      }
    }

    var i18nOptions = {
      // TODO: Fix loading of missing languages (e.g. en-US)
      detectFromHeaders: true,
      fallbackLng: "en",
      ns: "app",
      resGetPath: "locales/__lng__/__ns__.json",
      useCookie: true
    };

    app.title = "Contakti";

    app.configurePlugins({
      router: true,
      dialog: true,
      widget: true
    });

    // New modals add their backdrop above previous modals.
    // http://solvedstack.com/questions/bootstrap-3-0-multiple-modals-overlay
    $(document).on('show.bs.modal', '.modal', function () {
      var zIndex = 1040 + (10 * $('.modal:visible').length);
      $(this).css('z-index', zIndex);
      setTimeout(function () {
        $('.modal-backdrop').not('.modal-stack').css('z-index', zIndex - 1).addClass('modal-stack');
      }, 0);
    });

    i18n.init(i18nOptions, function () {
      app.start().then(function () {
        binder.binding = function (obj, view) {
          $(view).i18n();
        };

        $.extend($.fn.pickadate.defaults, {
          monthsFull: i18n.t("app:daterangepicker.month_names").split("\n"),
          weekdaysShort: i18n.t("app:daterangepicker.days_of_week").split("\n"),
          today: i18n.t("app:daterangepicker.ranges.today"),
          clear: i18n.t("app:daterangepicker.cancel"),
          close: i18n.t("app:daterangepicker.close"),
          labelMonthNext: i18n.t("app:daterangepicker.next_month"),
          labelMonthPrev: i18n.t("app:daterangepicker.prev_month"),
          labelMonthSelect: i18n.t("app:daterangepicker.select_month"),
          labelYearSelect: i18n.t("app:daterangepicker.select_year"),
          firstDay: i18n.lng() == 'en' ? 0 : 1
        });
      });

      //Replace "viewmodels" in the moduleId with "views" to locate the view.
      //Look for partial views in a "views" folder in the root.
      viewLocator.useConvention();

      //Show the app by setting the root view model for our application with a transition.
      app.setRoot("viewmodels/shell", "entrance");
    });
  });
});
