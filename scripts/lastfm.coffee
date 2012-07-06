#
# Description:
#   Last (or current) played song by a user in Last.fm
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_LASTFM_APIKEY
#
# Commands:
#   hubot what's playing <Last.fm user> - Returns song name and artist
#   hubot what is <Last.fm user> playing? - Returns song name and artist
#   hubot what's <Last.fm user> listening to - Returns song name and artist
#   hubot on lastfm <user> is <Last.fm user>- Returns song name and artist
#
# Author:
#   guilleiguaran 
#   simonista

module.exports = (robot) ->
  robot.hear /\u266B\s*([\w .-_]+)/i, (msg) ->
    getLatestTrack msg

  robot.respond /(?:what's|what is) playing ([\w .-_]+)/i, (msg) ->
    getLatestTrack msg

  robot.respond /(?:what's|what is) ([\w .-_]+) (?:playing|listening to)\?*/i, (msg) ->
    getLatestTrack msg

  getLatestTrack = (msg) ->
    name = escape(msg.match[1])
    users = robot.usersForFuzzyName(name)
    if users.length is 1
      user = users[0]
      user = user.lastfm_username or name
    else if users.length > 1
      msg.send getAmbiguousUserText users
      return
    else
      user = name

    apiKey = process.env.HUBOT_LASTFM_APIKEY
    msg.http('http://ws.audioscrobbler.com/2.0/?')
      .query(method: 'user.getrecenttracks', user: user, api_key: apiKey, format: 'json')
      .get() (err, res, body) ->
        results = JSON.parse(body)
        if results.error
          msg.send results.message
        else if results.recenttracks.track?
          tracks = results.recenttracks.track
          # tracks can be an array or an object :(
          song = tracks[0] || tracks
          msg.send "#{song.name} by #{song.artist['#text']}"
        else
          msg.send "#{user} hasn't listened to anything."

  getAmbiguousUserText = (users) ->
    "Be more specific, I know #{users.length} people named like that: #{(user.name for user in users).join(", ")}"

  robot.respond /(?:at|on) lastfm ([\w.-_]+) is ([\w.-_]+)[.!]*$/i, (msg) ->
    name = msg.match[1].trim()
    lastfm_username = msg.match[2].trim()

    users = robot.usersForFuzzyName(name)
    if users.length is 1
      user = users[0]
      user.lastfm_username = lastfm_username
      msg.send "Okay, I'll remember."
    else if users.length > 1
      msg.send getAmbiguousUserText users
    else
      msg.send "I don't know anything about #{name}."
