$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)

# FIXME A05E92A2: i'd like to just 'require anonydog'
require "anonydog/webapp/webapp"
run Anonydog::Webapp