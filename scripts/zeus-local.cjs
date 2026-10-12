const projectRoot = require('path').resolve(__dirname, '..')
process.chdir(projectRoot)
const path = require('path')
process.env.PATH = path.dirname(process.execPath) + path.delimiter + process.env.PATH
const cli = path.join(projectRoot, '.tools/zeus/node_modules/@zeppos/zeus-cli')
const fs = require('fs')
const qrTerminal = require('./.tools/zeus/node_modules/qrcode-terminal')
const generateQr = qrTerminal.generate
qrTerminal.generate = function (url, ...args) {
  const QRCode = require('./.tools/zeus/node_modules/qrcode-terminal/vendor/QRCode')
  const qr = new QRCode(-1, this.error)
  qr.addData(url)
  qr.make()
  fs.writeFileSync(path.join(projectRoot, 'previews/zepp-install-url.txt'), url)
  fs.writeFileSync(path.join(projectRoot, 'previews/zepp-qr-matrix.json'), JSON.stringify(qr.modules))
  return generateQr.call(this, url, ...args)
}
// Print the public authorization URL so a blocked browser launch can be completed manually.
const browserModule = require(path.join(cli, 'private-modules/zeppos-app-utils/dist/modules/open'))
const openBrowser = browserModule.default
browserModule.default = async (...args) => {
  if (typeof args[0] === 'string' && args[0].includes('project_redirect_uri')) console.log('Zepp sign-in link: ' + args[0])
  return openBrowser(...args)
}
require('./.tools/zeus/node_modules/module-alias').addAlias('zeppos-app-utils', path.join(cli, 'private-modules/zeppos-app-utils'))
require(path.join(cli, 'bin/main.js'))
