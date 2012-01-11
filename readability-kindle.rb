# encoding: UTF-8

require 'mechanize'
require 'json'
require 'uri'
require 'logger'

logger = Logger.new('readability-kindle.log')

logger.info 'Parsing config file'
config = JSON.parse(File.read(File.join(File.dirname(__FILE__), 'config.json')))

agent = Mechanize.new

logger.info 'Getting login form'
login = agent.get "http://www.readability.com/#{config['readability']['username']}/"
login.form.username = config["readability"]["username"]
login.form.password = config["readability"]["password"]

logger.info 'Submitting login form'
doc = Nokogiri::HTML login.form.submit.body

articles_ids = doc.css('#rdb-reading-list a.list-article-title').map do |a|
  a['href'].match(/[^\/]+$/).to_s
end

articles_ids.each do |article_id|
  logger.info "Delivering #{article_id}"
  agent.post "http://www.readability.com/api/kindle/v1/generator", "id" => article_id, "email" => config["kindle"]["email_address"]
  logger.info "Archiving #{article_id}"
  agent.get "http://www.readability.com/articles/#{article_id}/ajax/archive"
end


