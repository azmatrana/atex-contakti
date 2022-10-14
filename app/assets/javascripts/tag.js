
$(function () {
  $.serializeObject = function(data){
    var o = {};
    var a = data;
    $.each(a, function() {
       if (o[this.name]) {
           if (!o[this.name].push) {
               o[this.name] = [o[this.name]];
           }
           o[this.name].push(this.value || '');
       } else {
           o[this.name] = this.value || '';
       }
   });
   return o;
  };

  var priorityPrev;
  $('body').on( 'focus', '.prior select', function() {
    priorityPrev = $(this).val();
  })

  $('body').on( 'change', '.prior select', function() {
    submitPriority($(this).closest('form'));
  });

  function submitPriority(form$) {
    $.ajax({
      type: "PUT",
      cache: false,
      url: form$.attr('action') + "?" + form$.serialize(),
      data: form$.serialize(),
      contentType: "script",
      success: function (data) {
        console.log(data);
        $('.expireTimeForm select')

      },
      error: function () {
        form$.find('select').val(priorityPrev);
        console.log('error');
      }
    });
  }

  var timePrev;
  $('body').on( 'focus', '.expireTimeForm select', function() {
    timePrev = $(this).val();
  })

  $('body').on( 'change', '.expireTimeForm select', function() {
    submitPriority($(this).closest('form'));
  });
});