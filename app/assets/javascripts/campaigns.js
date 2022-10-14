$( document ).ready(function() {
  $(document).on("keyup", "#campaign-search-form #campaign-search-input", debounce(function(){
    $("#campaign-search-form").submit();
  }, 500));



  $(document).on("keyup", "#campaign_item-search-form #campaign_item-search-input", debounce(function(){
    $("#campaign_item-search-form").submit();
  }, 500));


  var last_campaign_open_el = document.querySelector(".last-campaign-openend");
  var all_campaigns_link    = document.querySelector(".all-campaing-link");

  $("body").on("click", ".campaign-items-modal-close", function(){
    if (last_campaign_open_el) last_campaign_open_el.classList.add('hide');
    if (all_campaigns_link) all_campaigns_link.classList.remove('hide');
  })

})
