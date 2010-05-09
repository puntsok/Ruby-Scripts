#!/usr/bin/env ruby
require 'rubygems'
require 'ruby-debug'
require 'open-uri'
require 'nokogiri'
require 'openssl' 

module Enumerable
  # see http://kourge.net/node/100
  def pluck(method, *args) 
    map { |x| x.send method, *args } 
  end 
  alias invoke pluck 
end
class String
  def remove_xml_declaration
    self.gsub( /\<\?xml.*\?\>/, '' )
  end
end
# http://situated.wordpress.com/2008/06/10/...
#   opensslsslsslerror-certificate-verify-failed-open-uri/
# also look in comments for other techniques
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

class Getter
  attr_accessor :url, :response, :doc,
                :title_node, :page_title, :app_name
  def initialize
    puts 'Getter object initialized.'
  end 
  def run
    clear_out_output_dir
    get_url_from_user
    get_url_into_response
    put_full_domain_inside
    parse_response_into_doc
    get_attrs_from_user
    get_title_node
    change_title_to page_title
    remove_extra_breadcrumbs
    remove_real_content
    extract_scripts
    change_title_in_head
    download_style_folder
    download_banner_images 
    add_webapp_class_to_body
    inline_display_block_for_control_panel  
    write_out_file
  end 
  def clear_out_output_dir
    system 'rm -r output/*'
  end
  def get_url_into_response
    open(url) do |f|
      puts "Fetched: #{f.base_uri}"
      @response = f.read
    end
  end  
  def add_webapp_class_to_body
    doc.at_css('body').set_attribute('class','webapp')
  end  
  def inline_display_block_for_control_panel
    panel = doc.at_css('#control-panel')
    panel.set_attribute('style','display:block')
    panel.inner_html = (1..2).inject('') do |r,o|
      r + "<span class='wp-button'><a href='#'>Button #{o.to_s}</a></span>"
    end
  end
  def change_title_in_head
    doc.at_css('title').inner_html = page_title + ': ' + app_name
  end
  def remove_real_content
    doc.at_css('#real-content').inner_html = "%= yield"
  end
  def remove_extra_breadcrumbs
    #breadcrumb_nodes = doc.css '.breadcrumbs a'
    first_breadcrumb = doc.css('.breadcrumbs a').first
    first_breadcrumb.parent.inner_html = first_breadcrumb.to_s + ' &gt; ' + app_name
    true
  end
  def write_out_file
    fh = File.new("output/index.html","w+")
    fh.puts doc.to_s.remove_xml_declaration
    fh.close
  end
  def download_banner_images
    doc.css('.header-montage img').each do |node| 
      src = node.attr('src')
      system "wget -P output/stylesheets/new-design/images #{src}"
      image_no_path =  src.split('/').last
      node.set_attribute( 'src', 'stylesheets/new-design/images/' + image_no_path )
    end 
    # optional, completely take out images
    doc.at_css('.header-montage').inner_html = nil
  end          
  def download_style_folder
    system "scp -r cew904@dev.dosa.northwestern.edu:" + 
      "/Users/cew904/nu-dev2/common/styles " +
      "output/stylesheets/"
    doc.css('head link[rel="stylesheet"]').each do |sheet|
      href = sheet.attr('href')
      p = href.split '/'
      new = 'stylesheets/' + p[-2] + '/' + p[-1]
      sheet.set_attribute('href', new)
    end
    doc.css('head link[rel~="shortcut"]').each do |sheet|
      href = sheet.attr('href')
      p = href.split '/'
      new = 'stylesheets/' + p[-3] + '/' + p[-2] + '/' + p[-1]
      sheet.set_attribute('href', new)
    end  
  end                  
  def parse_response_into_doc
    # don't put Nokogiri::HTML, otherwise self closing nodes don't have /, as in <br/>
    self.doc = Nokogiri::XML(response)
    # self.doc = Nokogiri::HTML(response)
  end
  def get_title_node
    self.title_node = doc.at_css '.page-title h1 span'
  end
  def change_title_to(str)
    title_node.inner_html = str
  end
  def get_url_from_user
    # print 'Please enter URL: '
    # user_input = gets
    # I have no idea why I have to use self below!
    # self.url = user_input.chomp
    # self.url = 'https://dev.dosa.northwestern.edu/orientation/about/wildcat-welcome-staff/ww-board-of-directors.html' 
    self.url = 'http://www.northwestern.edu/orientation/about/wildcat-welcome-staff/ww-board-of-directors.html' 
  end
  def get_attrs_from_user
    self.page_title = "%= page_title" 
    self.app_name = "%= app_name"
  end
  def extract_scripts
    doc.css('script').invoke :remove
    # previously: @response.gsub!(/<script.+?\/script>/m, '')
  end
  def put_full_domain_inside
    #@response.gsub! /a/, 'A'
    @response.gsub!(/"\//, '"http://www.northwestern.edu/')
    # @response.gsub!(/"\//, '"https://dev.dosa.northwestern.edu/')
  end
end

# make an instance and run
g = Getter.new.run