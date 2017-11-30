const i18n = require('../lib/i18n')
const vendoredVersions = require('../data/versions.json')
  .find(version => version.version === i18n.valexLatestStableVersion)
const {getLanguageNativeName} = require('locale-code')

// Supply all route handlers with a baseline `req.context` object
module.exports = function contextBuilder (req, res, next) {
  // Attach i18n object to request so any route handler can use it if needed
  req.i18n = i18n

  // Page titles, descriptions, etc
  const page = i18n.website[req.language].pages[req.path] || {}
  page.path = req.path

  req.context = {
    valexLatestStableVersion: i18n.valexLatestStableVersion,
    valexLatestStableTag: i18n.valexLatestStableTag,
    vendoredVersions: vendoredVersions,
    currentLocale: req.language,
    currentLocaleNativeName: getLanguageNativeName(req.language),
    locales: i18n.locales,
    page: page,
    localized: i18n.website[req.language],
    cookies: req.cookies
  }

  if (req.path !== '/' && req.context.page && !req.context.page.titled) {
    req.context.page.titled = true
    req.context.page.title = `${req.context.page.title} | Valex`
  }

  if (req.path.startsWith('/docs')) {
    req.context.docs = i18n.docs[req.language]
  }

  return next()
}
