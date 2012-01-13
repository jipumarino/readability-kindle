# encoding: UTF-8

require 'mechanize'
require 'nokogiri'
require 'json'
require 'logger'

@logger = Logger.new('readability-kindle.log')
@config = JSON.parse(File.read(File.join(File.dirname(__FILE__), 'config.json')))
@agent = Mechanize.new

def readability_url
  "http://www.readability.com/#{@config['readability']['username']}/"
end

def deliver_article(id)
  @logger.info "Delivering article #{id}"
  @agent.post "http://www.readability.com/api/kindle/v1/generator", "id" => id, "email" => @config["kindle"]["email_address"]
end

def archive_article(id)
  @agent.get "http://www.readability.com/articles/#{id}/ajax/archive"
end

def process_articles
  @logger.info "Processing articles"
  response = @agent.get readability_url
  return false if response.forms.size > 1

  doc = Nokogiri::HTML(response.body)

  articles_ids = doc.css('#rdb-reading-list a.list-article-title').map do |a|
    a['href'].match(/[^\/]+$/).to_s
  end

  @logger.info "Nothing to deliver" if articles_ids.empty?

  articles_ids.each do |article_id|
    deliver_article article_id
    archive_article article_id
  end

  return true
end

def try_to_login
  @logger.info "Trying to login"
  login_page = @agent.get readability_url
  login_page.form.username = @config["readability"]["username"]
  login_page.form.password = @config["readability"]["password"]
  login_page.form.submit
end

def main_loop
  @logger.info "Sleeping"
  sleep 60
  try_to_login if not process_articles
end

main_loop while true