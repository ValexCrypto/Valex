const List = require('list.js')
const queryString = require('query-string')
const setQueryString = require('set-query-string')
const lazyLoadImages = require('./lazy-load-images')

module.exports = function createFilterList () {
  // look for a filterable list on this page
  const list = document.querySelector('.filterable-list')
  if (!list || !list.parentElement) return

  // inherit initial query from `q` query param
  const filterInput = document.querySelector('.filterable-list-input')
  filterInput.value = queryString.parse(location.search).q || ''

  const opts = {
    listClass: 'filterable-list',
    searchClass: 'filterable-list-input',
    valueNames: [
      'listed-app-name',
      'listed-app-description',
      'listed-app-date',
      'listed-app-keywords'
    ]
  }
  const filterList = new List(list.parentElement.parentElement, opts)

  // trigger a search, in case there is an existing value in the text input
  filterList.search(filterInput.value)

  // update the query param every time a search is performed
  filterList.on('updated', function () {
    setQueryString({q: filterInput.value})
    list.querySelectorAll('img[data-src]').forEach(lazyLoadImages.addImage)
  })
}
