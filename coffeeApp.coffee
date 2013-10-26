express = require 'express'
routes = require './routes'
newrelic = require 'newrelic'
http = require 'http'
path = require 'path'
util = require 'util'
twitter = require 'twitter'
compressor = require 'node-minify'
grunt = require 'grunt'

# Grunt task
grunt.loadNpmTasks 'grunt-contrib-coffee'
grunt.tasks [], {}, ->
  grunt.log.ok "Grunt: Done running tasks!"

# Expres
app = express()

# Configs
app.set 'port', process.env.PORT || 3000
app.set 'views', path.join __dirname, 'views'
app.set 'view engine', 'jade'
app.use express.logger 'dev'
app.use express.bodyParser()
app.use express.methodOverride()
app.use app.router
app.use express.static(path.join(__dirname, "public"))

# Minify
new compressor.minify {
  type: 'uglifyjs',
  fileIn: 'assets/js/fBomb.js',
  fileOut: 'public/js/fBomb.min.js',
  callback: (err) ->  if err
    console.log 'minify: ' + err
  }
  
# Dev config
app.configure 'development', ->
  app.use express.errorHandler {
    dumpExceptions: true,
    showStack: true
    }
  app.locals.pretty = true 
  
# Prod config
app.configure 'production', ->
  app.use express.errorHandler()

tweets = []

twit = new twitter {
  consumer_key: process.env.consumer_key,
  consumer_secret: process.env.consumer_secret,
  access_token_key: process.env.oauth_token,
  access_token_secret: process.env.oauth_token_secret
}

twit.stream 'statuses/filter', {track:'fuck'}, (stream) ->
  id = 0
  stream.on 'data', (data) ->
    if data.geo
      tweets.push {text: data.text, coordinates: data.geo.coordinates, id:id++}
      
`getTweets = function() {return tweets;}`

eraseTweets = ->
  console.log("Erasing Tweets")
  tweets = []

setInterval eraseTweets, 5000

# Routes
app.get '/', routes.index
app.get '/data', routes.data

http.createServer(app).listen app.get('port'), ->
  console.log 'Express server listening on port ' + app.get 'port'
