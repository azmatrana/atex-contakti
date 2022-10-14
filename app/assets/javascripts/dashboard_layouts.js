// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js

(function($){
   function DashboardDesigner(list, designPanel, menu){
       this.list = $(list);
       this.designPanel = $(designPanel);
       this.widgetMenu = $(menu);
       this.form = this.designPanel.closest('form');
       this.layoutInput =  this.form.find('input#dashboard_layout_layout');
       this.namespace = list;
       this.initiate();
   }

   DashboardDesigner.prototype.initiate = function () {
       this.designPanel.gridster({
           widget_margins: [5, 5],
           widget_base_dimensions: [130, 130],
           max_cols: 4,
           min_rows: 3,
           min_cols: 4,
           autogenerate_stylesheet: true,
           avoid_overlapped_widgets: true,
           serialize_params: function($w, wgd) {
               return {
                   col: wgd.col, row: wgd.row, size_x: wgd.size_x, size_y: wgd.size_y, name: $w.data('wg-name')
               }
           },
           namespace: '#create-to-modal-dialog',
           resize: {
            enabled: true
           }
       });

       this.form.on('submit', this.onFormSubmit.bind(this));
       this.widgetMenu.on('click', 'li', this.onAddWidgetClicked.bind(this));
       this.designPanel.on('click', '.fa-times-circle', this.onRemoveWidgetClicked.bind(this));
       if (!!this.layoutInput.val()) { this.addWidgetsToDesignPanel()}
   };
   DashboardDesigner.prototype.onAddWidgetClicked = function (e) {
       var item = this.list.find("li[data-wg-name='"+ $(e.currentTarget).data("wg-name")+"']");
       this.addWidgetToDesignPanel(item, {col: 0, row: 0});
   };
    DashboardDesigner.prototype.addWidgetToDesignPanel = function (item, position) {
        this.designPanel.data('gridster').add_widget(item.prop('outerHTML'), position.size_x, position.size_y, position.col, position.row);
        this.widgetMenu.find("li[data-wg-name='"+item.data("wg-name")+"']").hide();
    };
    DashboardDesigner.prototype.onRemoveWidgetClicked = function (e) {
        var item = $(e.currentTarget).closest('li');
        this.designPanel.data('gridster').remove_widget(item);
        this.widgetMenu.find("li[data-wg-name='"+item.data("wg-name")+"']").show();
    };
    DashboardDesigner.prototype.onFormSubmit = function (e) {
         this.layoutInput.val(JSON.stringify(this.designPanel.data('gridster').serialize()));
    };
    DashboardDesigner.prototype.addWidgetsToDesignPanel = function () {
         var gridData = JSON.parse(this.layoutInput.val());
         var self = this;
        $.each(gridData, function(i, item){
            var el = self.list.find("li[data-wg-name='"+ item.name+"']").first();
            self.addWidgetToDesignPanel(el, item);
        })
    };

    DashboardDesigner.prototype.clear = function () {
      this.widgetMenu.find("li").show();
      this.designPanel.data('gridster').remove_all_widgets();
    };

    DashboardDesigner.prototype.getLayout = function () {
      return JSON.stringify(this.designPanel.data('gridster').serialize());
    };

   window.DashboardDesigner = DashboardDesigner;
})($);

(function($){
    function DynamicDashboard(grid){
        this.grid = $(grid);
        this.namespace = grid;
        this.widgetHeight = 320;
        this.widgetWidth = 400;
        this.maxGridWidth = 1400;
        this.minGridWidth = 1040;
        this.initiate();
        $(document).on('resize', this.onDocumentResize.bind(this))
            .on('reshape', this.onDocumentResize.bind(this));
    }

    DynamicDashboard.prototype.initiate = function () {
        var gridWidth = this.grid.parent().width();
        var gridWidth = (gridWidth < this.minGridWidth ? this.minGridWidth : (gridWidth > this.maxGridWidth ? this.maxGridWidth : gridWidth));
        var baseWidth = Math.floor((gridWidth - 20) / 4); // Max cols

        this.grid.gridster({
            widget_margins: [5, 5],
            max_cols: 4,
            draggable: {
                handle: 'h3'
            },
            avoid_overlapped_widgets: true,
            widget_base_dimensions: [baseWidth, 330]
        });
    };

    DynamicDashboard.prototype.onDocumentResize = function () {
        var gridWidth = this.grid.parent().width();
        var gridWidth = (gridWidth < this.minGridWidth ? this.minGridWidth : (gridWidth > this.maxGridWidth ? this.maxGridWidth : gridWidth));
        var baseWidth = Math.floor((gridWidth - 20) / 4); // Max cols

        if (this.grid.data('gridster')) {
          this.grid.data('gridster').resize_widget_dimensions({
            widget_base_dimensions: [baseWidth, 330],
            widget_margins: [5, 5]
          });
        }
    };

    window.DynamicDashboard = DynamicDashboard;
})($);

