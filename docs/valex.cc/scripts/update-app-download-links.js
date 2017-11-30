const {getPlatformFromUserAgent, getPlatformLabel} = require('platform-utils')

// Emphasize app download links for the visitor's OS (darwin|linux|win32)
// Platform is inferred from user agent

module.exports = function updateAppDownloadLinks () {
  const links = Array.from(document.querySelectorAll('a.app-download'))

  // No downloads links found on the page.
  if (!links.length) return

  const platform = getPlatformFromUserAgent()
  const matches = links.filter(link => link.classList.contains(platform))

  // No downloads found for the detected OS. Leave links untouched.
  if (!matches.length) return

  links.forEach(link => {
    link.style.display = link.classList.contains(platform)
      ? 'inline-block'
      : 'none'
  })

  if (matches.length === 1) {
    matches[0].textContent = `Download for ${getPlatformLabel(platform)}`
  }

  if (links.length > 1) {
    document.querySelector('#view-all-downloads').style.display = 'inline-block'
  }
}
