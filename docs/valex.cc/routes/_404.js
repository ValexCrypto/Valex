module.exports = (req, res) => {
  req.context.page.title = '404 Not Found | Valex'
  res.render('404', req.context)
}
