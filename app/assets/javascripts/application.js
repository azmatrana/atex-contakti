// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require_self
//= require jquery
//= require jquery_ujs
//= require jquery-ui
//= require jquery.ba-throttle-debounce.min
//= require twitter/bootstrap
//= require_directory ./components
//= require ckeditor/ckeditor.js
//= require ckeditor/config.js
//= require select2-full
//= require select2_locale_"fi"
//= require select2_locale_"sv"
//= require moment-with-locales
//= require moment-duration-format.js
//= require common

//= require daterangepicker
//= require date_range
//= require timepicker
//= require i18n/translations
//= require query_throttler
//= require header
//= require users
//= require agent_status
//= require submit_loader
//= require sms_templates
//= require locations
//= require reports
//= require sms
//= require weekly_schedule
//= require bootbox
//= require custom_confirm
//= require jquery.remotipart
//= require ./manager
//= require ./filesize
//= require task_mark_as_done_modal
//= require agents
//= require modulejs-1.5.0.min
//= require_directory ../../../vendor/assets/javascripts/extremia_flotcharts/modules
//= require ../../../vendor/assets/javascripts/extremia_flotcharts/extremia_flotchart.js
//= require knockout
//= require knockout.mapping
//= require gridster
//= require gridster.extension
//= require dashboard_layouts
//= require HTMLSelectElement.prototype.selectedOptions
//= require pikaday
//= require pikaday_locales
//= require bootstrap-switch-init
//= require img_upload_preview
//= require service_channels
//= require tag
//= require toastr
//= require stopwatch
//= require contacts
//= require campaigns
//= require viewer

if ( !window.console ) {
  window.console = new function() {
    this.log = function(str) {};
    this.dir = function(str) {};
  };
};
