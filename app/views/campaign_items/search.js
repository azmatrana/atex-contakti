$("#campaign_items-table-wrapper").html("<%= escape_javascript(render 'campaign_items/table/table', campaign_items: @campaign_items, campaign: @campaign, is_admin: @is_admin) %>");
