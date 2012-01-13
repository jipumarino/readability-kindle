# encoding: UTF-8

require 'mechanize'
require 'nokogiri'
require 'json'
require 'logger'

@logger = Logger.new('readability-kindle.log')

@logger.info 'Parsing config file'
@config = JSON.parse(File.read(File.join(File.dirname(__FILE__), 'config.json')))

@agent = Mechanize.new

def deliver_article(id)
  @logger.info "Delivering article #{id}"
  @agent.post "http://www.readability.com/api/kindle/v1/generator", "id" => id, "email" => @config["kindle"]["email_address"]
end

def archive_article(id)
  @logger.info "Archiving article #{id}"
  @agent.get "http://www.readability.com/articles/#{id}/ajax/archive"
end

def process_articles
  @logger.info "Processing articles"
  doc = Nokogiri::HTML(@agent.get("http://www.readability.com/#{@config['readability']['username']}/").body)

  articles_ids = doc.css('#rdb-reading-list a.list-article-title').map do |a|
    a['href'].match(/[^\/]+$/).to_s
  end

  if articles_ids.empty?
    @logger.info "Nothing to deliver"
  end

  articles_ids.each do |article_id|
    deliver_article article_id
    archive_article article_id
  end
end

def logged_in?
  @logger.info "Checking login"
  response = @agent.get "http://www.readability.com/#{@config['readability']['username']}/"
  response.forms.size == 1
end

def try_to_login
  @logger.info "Trying to login"
  login_page = @agent.get "http://www.readability.com/#{@config['readability']['username']}/"
  login_page.form.username = @config["readability"]["username"]
  login_page.form.password = @config["readability"]["password"]
  login_page.form.submit
end

def main_loop
  @logger.info "Sleeping"
  sleep 60
  if logged_in?
    process_articles
  else
    try_to_login
    process_articles if logged_in?
  end
end

main_loop while true