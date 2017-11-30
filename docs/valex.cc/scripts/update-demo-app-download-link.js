const {getPlatformFromUserAgent, getPlatformLabel} = require('platform-utils')

module.exports = function updateDemoAppDownloadLink () {
  if (!document.querySelector('#download-latest-release')) return
  const platform = getPlatformFromUserAgent()

  if (!platform) return

  const releaseServer = 'https://example.githubapp.com/updates/'
  let assetName

  if (platform === 'darwin') assetName = 'valex-mac.zip'
  if (platform === 'win32') assetName = 'valex-win.exe'
  if (platform === 'linux') assetName = 'valex-linux.zip'

  document.querySelector('#download-latest-release')
    .setAttribute('href', releaseServer + assetName)

  document.querySelector('#download-latest-release .label')
    .textContent = 'Download for ' + getPlatformLabel(platform)

  document.querySelector('#download-alternatives')
    .style.display = 'inline-block'
}
