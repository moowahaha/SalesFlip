require 'open-uri'
require 'hpricot'
require 'mechanize'

class SoftwareMarketplatzParser
  def initialize
  end

  def agent
    @agent ||= WWW::Mechanize.new
  end

  def parse
    @parsed_pages = []
    parse_index("http://#{uri.host}#{uri.path}")
    doc.search('//a').each do |a|
      if a.attributes['href'].match(/^\/f_liste/)
        parse_index("http://#{uri.host}/#{a.attributes['href']}")
      end
    end
  end

  def parse_index( page )
    puts "parsing index: #{page}"
    doc.search('//a').each do |a|
      if a.attributes['href'].match(/^firmeninformation/)
        parse_page(a.attributes['href']) #unless @parsed_pages.include?(a.attributes['href'])
      end
    end
  end

  def parse_page( page )
    puts "parsing page: #{page}"
    lead = User.find_by_email('mattbeedle@googlemail.com').leads.build :rating => 5, :source => 'Imported'
    p = agent.get Iconv.iconv('utf-8', 'iso-8859-1', "http://#{uri.host}/#{page}")
    fieldsets = p.search('//fieldset')
    fieldset = nil
    fieldsets.each do |f|
      fieldset = f if f.inner_html.match(/Allgemeine Informationen/)
    end
    lead.company = Iconv.iconv('utf-8', 'iso-8859-1', fieldset.inner_html.split('</b>')[1].strip_html)
    fieldset.inner_html.split('</b>').last.split('<br>').each_with_index do |data, index|
      case index
      when 1 then lead.address = Iconv.iconv('utf-8', 'iso-8859-1', data)
      when 2
        data =~ /([0-9]{5})/
        lead.postal_code = $1
        lead.city = Iconv.iconv('utf-8', 'iso-8859-1', data.split(/\s/).last)
      when 3 then lead.phone = Iconv.iconv('utf-8', 'iso-8859-1', data)
      #when 4 then lead.fax = data
      when 7
        name = data.split('</p>').first.gsub(/,[^,]*/, '')
        puts name
        if result = name.match(/^[\w]{0,5}\./)
          lead.title = result[0].gsub(/\./, '')
          name.gsub!(/#{result[0]}/, '').strip
        end
        names = name.strip.split(/\s/)
        lead.first_name = Iconv.iconv('utf-8', 'iso-8859-1', names.shift)
        lead.last_name = Iconv.iconv('utf-8', 'iso-8859-1', names.join(' '))
      end
    end
    (-6..-1).to_a.each do |i|
       fieldset.inner_html.split('<p>')[i]
    end
    add_fieldset(p.search('//fieldset')[-6], lead) if p.search('//fieldset')[-6]
    add_fieldset(p.search('//fieldset')[-5], lead) if p.search('//fieldset')[-5]
    add_fieldset(p.search('//fieldset')[-4], lead) if p.search('//fieldset')[-4]
    add_fieldset(p.search('//fieldset')[-3], lead)
    add_fieldset(p.search('//fieldset')[-2], lead)
    p.links.each do |link|
      if link.text.match(/Homepage/)
        begin
          clicked = link.click
          lead.website = clicked.uri.host
        rescue
        end
      end
    end
    lead.notes.gsub!(/<img[^>]*>/, '')
    lead.notes.gsub!(/<a[^<]*Homepage<\/a>/, lead.website) if lead.website
    lead.notes.gsub!(/<a[^<]*E-Mail<\/a>/, '')
    lead.notes.gsub!(/<a href="/, '<a target="_blank" href="http://www.software-marktplatz.de/')
    lead.do_not_notify = true
    lead.do_not_log = true
    if l = Lead.first(:first_name => lead.first_name, :last_name => lead.last_name, :website => lead.website)
      puts "#{l.email} exists"
    else
      lead.save
    end
    @parsed_pages << page
  rescue
  end

  def add_fieldset( fieldset, lead )
    unless fieldset.inner_html.match(/Services oder Produkte sind/)
      lead.notes = (lead.notes || '') + "<fieldset>#{Iconv.iconv('utf-8', 'iso-8859-1', fieldset.inner_html)}</fieldset>"
    else
      lead.notes = (lead.notes || '') + "<fieldset>Services oder Produkte sind geeignet für Betriebsgrössen (Anzahl der Mitarbeiter)"
      html = Iconv.iconv('utf-8', 'iso-8859-1', fieldset.inner_html).to_a.first
      if html.match(/grafik\/haken\.gif[^<]*1-9 Mitarbeiter">/)
        lead.notes = (lead.notes || '') + '<br/>1 - 9'
      end
      if html.match(/grafik\/haken\.gif[^<]*10-49 Mitarbeiter">/)
        lead.notes = (lead.notes || '') + '<br/>10 - 49'
      end
      if html.match(/grafik\/haken\.gif[^<]*50-249 Mitarbeiter">/)
        lead.notes = (lead.notes || '') + '<br/>50 - 249'
      end
      if html.match(/grafik\/haken\.gif[^<]*250-500 Mitarbeiter">/)
        lead.notes = (lead.notes || '') + '<br/>250 - 500'
      end
      if html.match(/grafik\/haken\.gif[^<]*als 500 Mitarbeiter">/)
        lead.notes = (lead.notes || '') + '<br/>500+'
      end
      lead.notes += '</fieldset>'
    end
  end

  def parsed_pages
    @parsed_pages
  end

  def uri
    @uri ||= URI.parse('http://www.software-marktplatz.de/itanbieter_deutschland-d.html')
  end

  def doc
    @doc ||= Hpricot(open("http://#{uri.host}#{uri.path}"))
  end
end
