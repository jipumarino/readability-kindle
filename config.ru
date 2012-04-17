# This file goes in domain.com/config.ru
require 'rubygems'
require 'sinatra'
 
set :env,  :production
disable :run

require './readability-kindle.rb'

run Sinatra::Application