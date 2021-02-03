require 'bunny'
require "msgpack"

Handler = Proc.new do |req, res|
  user = req.body['user']
  user = req.body['repo']

  puts {'user': user, 'repo': repo}.to_msgpack,

  res.status = 302
  res.headers['location'] = '/instructions'
end