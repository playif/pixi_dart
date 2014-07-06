part of PIXI;

class BitmapFontLoader extends Loader {


  String baseUrl;

  RegExp baseReg = new RegExp("[^\/]*\$");



  BitmapFontLoader(String url, bool crossorigin)
  :super(url, crossorigin) {

  }

  load() {
    this.ajaxRequest = AjaxRequest();
    this.ajaxRequest.onReadyStateChange.listen((e) {
      this.onXMLLoaded();
    });

    this.ajaxRequest.open('GET', this.url, async: true);
    if (this.ajaxRequest.overrideMimeType) this.ajaxRequest.overrideMimeType('application/xml');
    this.ajaxRequest.send(null);
  }

  onXMLLoaded() {
    if (this.ajaxRequest.readyState == 4) {
      if (this.ajaxRequest.status == 200 || window.location.protocol.indexOf('http') == -1) {
        var responseXML = this.ajaxRequest.responseXml;
        //|| /MSIE 9/i.test(navigator.userAgent) || navigator.isCocoonJS
        if (responseXML == null) {
          if (typeof(window.DOMParser) == 'function') {
            var domparser = new DOMParser();
            responseXML = domparser.parseFromString(this.ajaxRequest.responseText, 'text/xml');
          } else {
            var div = document.createElement('div');
            div.innerHTML = this.ajaxRequest.responseText;
            responseXML = div;
          }
        }

        var textureUrl = this.baseUrl + responseXML.getElementsByTagName('page')[0].getAttribute('file');
        var image = new ImageLoader(textureUrl, this.crossorigin);
        this.texture = image.texture.baseTexture;

        Map data = {
        };
        var info = responseXML.getElementsByTagName('info')[0];
        var common = responseXML.getElementsByTagName('common')[0];
        data['font'] = info.getAttribute('face');
        data['size'] = int.parse(info.getAttribute('size'));
        data['lineHeight'] = int.parse(common.getAttribute('lineHeight'));
        data['chars'] = {
        };

        //parse letters
        var letters = responseXML.getElementsByTagName('char');

        for (var i = 0; i < letters.length; i++) {
          var charCode = int.parse(letters[i].getAttribute('id'));

          var textureRect = new Rectangle(
              int.parse(letters[i].getAttribute('x')),
              int.parse(letters[i].getAttribute('y')),
              int.parse(letters[i].getAttribute('width')),
              int.parse(letters[i].getAttribute('height'))
          );

          data['chars'][charCode] = {
              'xOffset': int.parse(letters[i].getAttribute('xoffset')),
              'yOffset': int.parse(letters[i].getAttribute('yoffset')),
              'xAdvance': int.parse(letters[i].getAttribute('xadvance')),
              'kerning': {
              },
              'texture': TextureCache[charCode] = new Texture(this.texture, textureRect)
          };
        }

        //parse kernings
        var kernings = responseXML.getElementsByTagName('kerning');
        for (int i = 0; i < kernings.length; i++) {
          var first = int.parse(kernings[i].getAttribute('first'));
          var second = int.parse(kernings[i].getAttribute('second'));
          var amount = int.parse(kernings[i].getAttribute('amount'));

          data['chars'][second].kerning[first] = amount;

        }

        BitmapText.fonts[data.font] = data;

        var scope = this;
        image.addEventListener('loaded', () {
          scope.onLoaded();
        });
        image.load();
      }
    }
  }

  onLoaded ()
  {
    this.dispatchEvent(new PixiEvent()
      ..type = 'loaded'
      ..content = this);
  }
}