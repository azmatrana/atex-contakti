if (!Modernizr.touch && $('#menu').is(':visible'))
  $('.container-fluid').removeClass('menu-hidden');

if (Modernizr.touch)
  $('#menu').removeClass('hidden-xs');

// handle menu toggle button action
window.toggleMenuHidden = function () {
  if ($('.menu-right-visible').length)
    $('body').removeClass('menu-right-visible');

  $('body').toggleClass('menu-hidden');
  $('body').toggleClass('menu-left-visible');
  $('#menu').removeClass('hidden-xs');
  $('.navbar.main .btn-navbar, #menu .btn-navbar').blur();
  resizeNiceScroll();
};

window.showMenu = function () {
  if ($('.menu-right-visible').length)
    $('body').removeClass('menu-right-visible');

  $('body').addClass('menu-left-visible');
  $('body').removeClass('menu-hidden');
  $('#menu').removeClass('hidden-xs');
  resizeNiceScroll();
};

window.hideMenu = function () {
  $('body').removeClass('menu-left-visible');
  $('body').addClass('menu-hidden');
  resizeNiceScroll();
};

$(document).ready(function () {
  // main menu visibility toggle
  $('.navbar.main .btn-navbar, #menu .btn-navbar').on('click', function () {
    toggleMenuHidden();
    if ($('.menu-left-visible').length) {
      if (!localStorage.getItem('main-menu-visible')) {
        localStorage.setItem('main-menu-visible', 1);
      }
    } else {
      localStorage.removeItem('main-menu-visible');
    }
  });

  if (localStorage.getItem('main-menu-visible') && !$('body.users_details').length) {
    setTimeout(showMenu(), 500);
  }

});
