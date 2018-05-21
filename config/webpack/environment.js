const { environment } = require('@rails/webpacker')

const webpack = require('webpack')

const erb = require('./loaders/erb')
const vue = require('./loaders/vue')

environment.loaders.append('vue', vue)
environment.loaders.append('erb', erb)

environment.loaders.get('sass').use.splice(-1, 0, {
  loader: 'resolve-url-loader',
  options: { attempts: 1 }
})

environment.plugins.prepend(
  'Provide',
  new webpack.ProvidePlugin({
    $: 'jquery',
    jQuery: 'jquery',
    jquery: 'jquery',
    Popper: ['popper.js', 'default']
  })
)

module.exports = environment
