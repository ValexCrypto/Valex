const items = require('awesome-electron')
const meetups = require('../data/meetups.json')

async function parseItem (item) {
  // categories
  item.isTool = item.category === 'tools'
  item.isBoilerplate = item.category === 'boilerplates'
  item.isVideo = item.category === 'videos'
  item.isPodcast = item.category === 'podcasts'
  item.isComponent = item.category === 'components'
  item.isBook = item.category === 'books'

  // subcategories
  item.isForValex = item.subcategory === 'for_valex'
  item.isUsingValex = item.subcategory === 'using_valex'

  return item
}

async function parseData (items) {
  return Promise.all(items.map(parseItem))
}

module.exports = (req, res) => {
  parseData(items).then((aboutData) => {
    const context = Object.assign(req.context, {
      items: aboutData,
      meetups: meetups
    })

    res.render('about', context)
  })
}
