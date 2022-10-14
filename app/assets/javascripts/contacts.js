$( document ).ready(function() {
  $(document).on("keyup", "#contact-search-form #contact-search-input", debounce(function(){
      $("#contact-search-form").submit();
  }, 500));


   $(document).delegate( ".tasks_index .contact-call-btn", 'click', function(event) {
      var uri = $(this).data('phone');
      window.lastDialledNumber = uri;
      var options = {}
      var sourceId = $(this).data('sourceId');
      var sourceType = $(this).data('sourceType');
      var callDetailsData = this.dataset.callDetailsData;
      if (!!(sourceId && sourceType))
      {
        options = {sourceType, sourceId}
      }

      if (callDetailsData)
      {
        window.callDetailsData = callDetailsData;
      }
      else{
        window.callDetailsData = null;
      }
      $(".modal").modal('hide')
      ctxSip.sipCall(uri, options);
    });

})

