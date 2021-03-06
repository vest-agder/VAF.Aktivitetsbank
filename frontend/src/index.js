require('./main.css')

require('file?name=/images/nfk-logo.png!../images/nfk-logo.png')
require('file?name=/images/vaf-logo.png!../images/vaf-logo.png')
require('file?name=/images/vaf-logo.svg!../images/vaf-logo.svg')
require('file?name=/images/vfk-logo.png!../images/vfk-logo.png')
require('file?name=/images/vfk-logo.svg!../images/vfk-logo.svg')
require('file?name=/images/rogfk-logo.png!../images/rogfk-logo.png')

require('ace-css/css/ace.css')

var Elm = require('./Main.elm')

var configuredLogo = '#{Logo}'
var logo = (configuredLogo[0] !== '#') ? configuredLogo : './images/vaf-logo.png'

var configuredApiUrl = '#{ApiUrl}'
var apiUrl = (configuredApiUrl[0] !== '#') ? configuredApiUrl : API_URL

Elm.Main.embed(document.getElementById('root'), {
  currentTime: Date.now(),
  apiEndpoint: apiUrl,
  vafLogo: logo
})
