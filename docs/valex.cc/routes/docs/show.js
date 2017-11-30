const i18n = require('../../lib/i18n')

module.exports = (req, res, next) => {
  const doc = i18n.docs[req.language][req.path]
  if (!doc) return next()

  const context = Object.assign(req.context, {
    doc: doc,
    page: {
      title: `${doc.title} | Valex`,
      description: doc.description
    },
    layout: 'docs'
  })

  res.render('docs/show', context)
}
