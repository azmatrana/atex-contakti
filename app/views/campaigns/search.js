$("#campaigns-table-wrapper").html("<%= escape_javascript(render 'campaigns/table', campaigns: @campaigns) %>");
