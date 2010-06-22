require File.dirname(__FILE__) + '/output'
require File.dirname(__FILE__) + '/puller'
#require File.dirname(__FILE__) + '/logger'

gem 'kronos', '>= 0.1.6'
require 'kronos'
require 'uri'

class SourcePuller < Puller

  def initialize
    @base_uri       = 'http://www.michigan.gov/som/0,1607,7-192-29938_54272_54378---,00.html'
    @details_folder = Output.dir  '/../cache/raw/source/detail'
    @index_data     = Output.file '/../cache/raw/source/index.yml'
    @index_html     = Output.file '/../cache/raw/source/index.html'
   # @pull_log       = Output.file '/../cache/raw/source/pull_log.yml'
    super
  end

  protected

  def get_metadata(doc)
	  paragraphs=doc.xpath("//p[@style='padding-left: 7pt; text-indent: -8pt; margin-bottom: 0; margin-top: 0;']")
    
	  metadata=[]
	  paragraphs.each do |p|
      a_tag=p.css("a").first
      title=a_tag["title"]
      next if title.nil? or title.empty? 

      format_key=translate_img_to_key(p.css("img").first)
      

      link=a_tag["href"]
      #If local link make appropraite changes
      link="http://michigan.gov"+link if link.match(/^\//)
      #Add http:// if it isn't there
      link="http://"+link if link.match(/^http:\/\//).nil?
   
      url=link.scan(/^http:\/\/.*?\//).first
      org_name=url.gsub("http://","").chop
		metadata<<{
			:title=>a_tag.inner_text,
			:description=>U.multi_line_clean(title),
      :url=>url,
      :organization=>{:name=>org_name},
			:downloads=>[{:format=>format_key.intern, :url=>link }]
		}
	  end

	metadata
  end


	def parse_metadata(metadata)
			metadata[:source_type]="dataset"
			metadata[:catalog_name]="michigan.gov"
			metadata[:catalog_url]=@base_uri
			metadata[:frequency]="unknown"
		  metadata[:organization][:url]=metadata[:url] 
      metadata
	end

  def translate_img_to_key(img_node)
    return "html" if img_node.nil?
    case img_node["alt"]
    when "Shapefile" : "shp"
    when "Excel icon": "xls"
    when "DBF icon"  : "dbf"
    when "ZIP icon"  : "zip"
    else               "html"
    end
  end

end
