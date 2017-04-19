$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)

# FIXME A05E92A2 was `require 'anonydog' but requiring webapp meant trying to
# connect to rabbitmq
require "anonydog/webhook/webhook"
run Anonydog::Webhook