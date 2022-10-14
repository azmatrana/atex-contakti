function readURL(input, previewElementId) {
  if (input.files && input.files[0]) {
    var reader = new FileReader();

    reader.onload = function (e) {
      $('#'+ previewElementId)
        .attr('src', e.target.result)
        .removeClass('hide');
    };

    reader.readAsDataURL(input.files[0]);
  }
}
