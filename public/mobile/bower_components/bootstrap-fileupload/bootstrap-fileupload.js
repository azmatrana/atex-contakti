/* ===========================================================
 * Bootstrap: fileupload.js v3.1.3
 * http://jasny.github.com/bootstrap/javascript/#fileupload
 * ===========================================================
 * Copyright 2012-2014 Arnold Daniels
 *
 * Licensed under the Apache License, Version 2.0 (the "License")
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ========================================================== */

+function ($) { "use strict";

  var isIE = window.navigator.appName == 'Microsoft Internet Explorer'

  // FILEUPLOAD PUBLIC CLASS DEFINITION
  // =================================

  var Fileupload = function (element, options) {
    this.$element = $(element)

    this.$input = this.$element.find(':file')
    if (this.$input.length === 0) return

    this.name = this.$input.attr('name') || options.name

    this.$hidden = this.$element.find('input[type=hidden][name="' + this.name + '"]')
    if (this.$hidden.length === 0) {
      this.$hidden = $('<input type="hidden">').insertBefore(this.$input)
    }

    this.$preview = this.$element.find('.fileupload-preview')
    var height = this.$preview.css('height')
    if (this.$preview.css('display') !== 'inline' && height !== '0px' && height !== 'none') {
      this.$preview.css('line-height', height)
    }

    this.original = {
      exists: this.$element.hasClass('fileupload-exists'),
      preview: this.$preview.html(),
      hiddenVal: this.$hidden.val()
    }

    this.listen()
  }

  Fileupload.prototype.listen = function() {
    this.$input.on('change.bs.fileupload', $.proxy(this.change, this))
    $(this.$input[0].form).on('reset.bs.fileupload', $.proxy(this.reset, this))

    this.$element.find('[data-trigger="fileupload"]').on('click.bs.fileupload', $.proxy(this.trigger, this))
    this.$element.find('[data-dismiss="fileupload"]').on('click.bs.fileupload', $.proxy(this.clear, this))
  },

  Fileupload.prototype.change = function(e) {
    var files = e.target.files === undefined ? (e.target && e.target.value ? [{ name: e.target.value.replace(/^.+\\/, '')}] : []) : e.target.files

    e.stopPropagation()

    if (files.length === 0) {
      this.clear()
      this.$element.trigger('clear.bs.fileupload')
      return
    }

    this.$hidden.val('')
    this.$hidden.attr('name', '')
    this.$input.attr('name', this.name)

    var file = files[0]

/*    if (this.$preview.length > 0 && (typeof file.type !== "undefined" ? file.type.match(/^image\/(gif|png|jpeg)$/) : file.name.match(/\.(gif|png|jpe?g)$/i)) && typeof FileReader !== "undefined") {
      var reader = new FileReader()
      var preview = this.$preview
      var element = this.$element

      reader.onload = function(re) {
        var $img = $('<img>')
        $img[0].src = re.target.result
        files[0].result = re.target.result

        element.find('.fileupload-filename').text(file.name)

        // if parent has max-height, using `(max-)height: 100%` on child doesn't take padding and border into account
        if (preview.css('max-height') != 'none') $img.css('max-height', parseInt(preview.css('max-height'), 10) - parseInt(preview.css('padding-top'), 10) - parseInt(preview.css('padding-bottom'), 10)  - parseInt(preview.css('border-top'), 10) - parseInt(preview.css('border-bottom'), 10))

        preview.html($img)
        element.addClass('fileupload-exists').removeClass('fileupload-new')

        element.trigger('change.bs.fileupload', files)
      }

      reader.readAsDataURL(file)
    } else {*/
      this.$element.find('.fileupload-filename').text(file.name)
      this.$preview.text(file.name)

      this.$element.addClass('fileupload-exists').removeClass('fileupload-new')

      this.$element.trigger('change.bs.fileupload')
/*    }*/
  },

  Fileupload.prototype.clear = function(e) {
    if (e) e.preventDefault()

    this.$hidden.val('')
    this.$hidden.attr('name', this.name)
    this.$input.attr('name', '')

    //ie8+ doesn't support changing the value of input with type=file so clone instead
    if (isIE) {
      var inputClone = this.$input.clone(true);
      this.$input.after(inputClone);
      this.$input.remove();
      this.$input = inputClone;
    } else {
      this.$input.val('')
    }

    this.$preview.html('')
    this.$element.find('.fileupload-filename').text('')
    this.$element.addClass('fileupload-new').removeClass('fileupload-exists')

    if (e !== undefined) {
      this.$input.trigger('change')
      this.$element.trigger('clear.bs.fileupload')
    }
  },

  Fileupload.prototype.reset = function() {
    this.clear()

    this.$hidden.val(this.original.hiddenVal)
    this.$preview.html(this.original.preview)
    this.$element.find('.fileupload-filename').text('')

    if (this.original.exists) this.$element.addClass('fileupload-exists').removeClass('fileupload-new')
     else this.$element.addClass('fileupload-new').removeClass('fileupload-exists')

    this.$element.trigger('reset.bs.fileupload')
  },

  Fileupload.prototype.trigger = function(e) {
    this.$input.trigger('click')
    e.preventDefault()
  }


  // FILEUPLOAD PLUGIN DEFINITION
  // ===========================

  var old = $.fn.fileupload

  $.fn.fileupload = function (options) {
    return this.each(function () {
      var $this = $(this),
          data = $this.data('bs.fileupload')
      if (!data) $this.data('bs.fileupload', (data = new Fileupload(this, options)))
      if (typeof options == 'string') data[options]()
    })
  }

  $.fn.fileupload.Constructor = Fileupload


  // FILEINPUT NO CONFLICT
  // ====================

  $.fn.fileupload.noConflict = function () {
    $.fn.fileupload = old
    return this
  }


  // FILEUPLOAD DATA-API
  // ==================

  $(document).on('click.fileupload.data-api', '[data-provides="fileupload"]', function (e) {
    var $this = $(this)
    if ($this.data('bs.fileupload')) return
    $this.fileupload($this.data())

    var $target = $(e.target).closest('[data-dismiss="fileupload"],[data-trigger="fileupload"]');
    if ($target.length > 0) {
      e.preventDefault()
      $target.trigger('click.bs.fileupload')
    }
  })

}(window.jQuery);
