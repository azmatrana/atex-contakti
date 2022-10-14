class ChatUtils {
 static replaceURLs = (message) => {
    if (!message) return '';
    if ( message.includes("<iframe") ) return message;
    var urlRegex = /(((https?:\/\/)|(www\.))[^\s]+)/g;
    let new_message = message.replace(urlRegex, function (url) {
      var hyperlink = url;
      if (!hyperlink.match('^https?:\/\/')) {
        hyperlink = 'http://' + hyperlink;
      }
      return '<a href="' + hyperlink + '" target="_blank" rel="noopener noreferrer">' + url + '</a>'
    });

    return new_message;
  }

  static replaceAllNewLines = (message) => {
    if (!message) return '';
    return message.replace(/\n/g, '<br/>');
  }

  static convertHtmlToText = (html) => {
    html = html.replace(/<style([\s\S]*?)<\/style>/gi, '');
    html = html.replace(/<script([\s\S]*?)<\/script>/gi, '');
    html = html.replace(/<\/div>/ig, '\n');
    html = html.replace(/<\/li>/ig, '\n');
    html = html.replace(/<li>/ig, '  *  ');
    html = html.replace(/<\/ul>/ig, '\n');
    html = html.replace(/<\/p>/ig, '\n');
    html = html.replace(/<br\s*[\/]?>/gi, "\n");
    html = html.replace(/<[^>]+>/ig, '');
    return html
  }

  static getUrlParams = (url) => {
    var params = {};
    (url + '?').split('?')[1].split('&').forEach(
      function (pair) {
        pair = (pair + '=').split('=').map(decodeURIComponent);
        if (pair[0].length) {
          params[pair[0]] = pair[1];
        }
      });

    return params;
  }

  static displayPrice(price){
    return Number(price).toFixed(2);
  }
};

export default ChatUtils