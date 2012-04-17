# encoding: UTF-8

require 'mechanize'
require 'nokogiri'
require 'json'
require 'sinatra'

def readability_url
  "http://www.readability.com/#{@config['readability']['username']}/"
end

def deliver_article(id)
  @agent.post "http://www.readability.com/api/kindle/v1/generator", "id" => id, "email" => @config["kindle"]["email_address"]
end

def archive_article(id)
  @agent.get "http://www.readability.com/articles/#{id}/ajax/archive"
end

def favorite_article(id)
  @agent.get "http://www.readability.com/articles/#{id}/ajax/favorite"
end

def process_articles
  response = @agent.get readability_url
  return false if response.forms.size > 1

  doc = Nokogiri::HTML(response.body)

  articles_ids = doc.css('#rdb-reading-list a.list-article-title').map do |a|
    a['href'].match(/[^\/]+$/).to_s
  end

  articles_ids.each do |article_id|
    deliver_article article_id
    archive_article article_id
    favorite_article article_id
  end

  return articles_ids.size
end

def try_to_login
  login_page = @agent.get readability_url
  login_page.form.username = @config["readability"]["username"]
  login_page.form.password = @config["readability"]["password"]
  login_page.form.submit
end

get '/' do
  @config ||= JSON.parse(File.read(File.join(File.dirname(__FILE__), 'config.json')))
  @agent ||= Mechanize.new
  try_to_login
  processed_articles = process_articles.to_s
  '<html><head><title>→K</title><link rel="apple-touch-icon" href="apple-touch-icon.png"><link rel="shortcut icon" href="favicon.ico"></head><body><div style="font-family:sans-serif;">'+processed_articles+' artículos procesados</div></body></html>'
end
