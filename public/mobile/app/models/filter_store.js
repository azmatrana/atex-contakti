define(["jquery", "knockout", "i18next", "moment"], function($, ko, i18n, moment) {
    function FilterStore(data) {
        var self = this;

        this.availableCategories = [
            {key: 'open_to_all', name: i18n.t('app:tasks.filtering.category.open_to_all')},
            {key: 'created_by_me', name: i18n.t('app:tasks.filtering.category.created_by_me')},
            {key: 'assigned_to_me', name: i18n.t('app:tasks.filtering.category.assigned_to_me')},
            {key: 'assigned_to_other', name: i18n.t('app:tasks.filtering.category.assigned_to_other')},
            {key: 'i_am_following', name: i18n.t('app:tasks.filtering.category.i_am_following')}
        ];
        this.availableStatuses = [
            {key: 'new', name: i18n.t('app:tasks.filtering.status.new')},
            {key: 'open', name: i18n.t('app:tasks.filtering.status.open')},
            {key: 'waiting', name: i18n.t('app:tasks.filtering.status.waiting')},
            {key: 'ready', name: i18n.t('app:tasks.filtering.status.ready')}
        ];
        this.availablePriorities = [
            {key: 'red_alert', name: i18n.t('app:tasks.filtering.priority.red_alert')},
            {key: 'yellow_alert', name: i18n.t('app:tasks.filtering.priority.yellow_alert')},
            {key: 'urgent', name: i18n.t('app:tasks.filtering.priority.urgent')}
        ];
        this.availableMediaChannels = [
            {key: 'email', name: i18n.t('app:tasks.media_channel.email')},
            {key: 'web_form', name: i18n.t('app:tasks.media_channel.web_form')},
            {key: 'call', name: i18n.t('app:tasks.media_channel.call')},
            {key: 'internal', name: i18n.t('app:tasks.media_channel.internal')},
            {key: 'chat', name: i18n.t('app:tasks.media_channel.chat')},
            {key: 'sms', name: i18n.t('app:tasks.media_channel.sms')}
        ];
        var lastXDays = i18n.t('app:daterangepicker.ranges.last_x_days');
        this.availableDateRangeSelections = [
            {key: '', name: i18n.t('app:daterangepicker.no_time')},
            {key: 'today', name: i18n.t('app:daterangepicker.ranges.today')},
            {key: 'yesterday', name: i18n.t('app:daterangepicker.ranges.yesterday')},
            {key: 'last_7_days', name: lastXDays.replace('{{days}}', 7)},
            {key: 'last_30_days', name: lastXDays.replace('{{days}}', 30)},
            {key: 'this_month', name: i18n.t('app:daterangepicker.ranges.this_month')},
            {key: 'last_month', name: i18n.t('app:daterangepicker.ranges.last_month')},
            {key: 'custom_range', name: i18n.t('app:daterangepicker.custom_range')}
        ];

        this.searchWords = ko.observable('');

        this.selectedCategories = ko.observableArray([
            'open_to_all',
            'created_by_me',
            'assigned_to_me'
        ]);
        this.selectedStatuses = ko.observableArray([
            'new',
            'open',
            'waiting'
        ]);
        this.selectedServiceChannels = ko.observableArray([]);
        this.selectedMediaChannels = ko.observableArray([
            'email',
            'web_form',
            'call',
            'internal',
            'chat',
            'sms'
        ]);
        this.selectedPriorities = ko.observableArray([]);
        this.selectedTags = ko.observableArray('');
        this.selectedDateRangeSelection = ko.observable(null);
        this.selectedDateRangeStart = ko.observable(null);
        this.selectedDateRangeEnd = ko.observable(null);

        this.selectedDateRangeSelection.subscribe(function(newValue) {
            var format = '';
            if (newValue == 'today') {
                self.selectedDateRangeStart(
                    moment().startOf('day')
                );
                self.selectedDateRangeEnd(
                    moment().endOf('day')
                );
            } else if (newValue == 'yesterday') {
                self.selectedDateRangeStart(
                    moment().subtract(1, 'days').startOf('day')
                );
                self.selectedDateRangeEnd(
                    moment().subtract(1, 'days').endOf('day')
                );
            } else if (newValue == 'last_7_days') {
                self.selectedDateRangeStart(
                    moment().subtract(7, 'days').startOf('day')
                );
                self.selectedDateRangeEnd(
                    moment().endOf('day')
                );
            } else if (newValue == 'last_30_days') {
                self.selectedDateRangeStart(
                    moment().subtract(30, 'days').startOf('day')
                );
                self.selectedDateRangeEnd(
                    moment().endOf('day')
                );
            } else if (newValue == 'this_month') {
                self.selectedDateRangeStart(
                    moment().startOf('month')
                );
                self.selectedDateRangeEnd(
                    moment().endOf('day')
                );
            } else if (newValue == 'last_month') {
                self.selectedDateRangeStart(
                    moment().subtract(1, 'months').startOf('month')
                );
                self.selectedDateRangeEnd(
                    moment().subtract(1, 'months').endOf('month')
                );
            } else if (newValue == 'custom_range') {
                self.selectedDateRangeStart(null);
                self.selectedDateRangeEnd(null);
            }
        });
    }

    return FilterStore;
});
