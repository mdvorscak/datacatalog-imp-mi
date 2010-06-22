require File.dirname(__FILE__) + '/output'
require File.dirname(__FILE__) + '/puller'
#require File.dirname(__FILE__) + '/logger'

require 'uri'

class OrganizationPuller < Puller

  def initialize
    @base_uri       = 'http://www.michigan.gov/som/0,1607,7-192-29701_29702_30045---FI,00.html'
    @bonus_uri      = 'http://www.michigan.gov/som/0,1607,7-192-29938_54272_54378---,00.html'
    @details_folder = Output.dir  '/../cache/raw/organization/detail'
    @index_data     = Output.file '/../cache/raw/organization/index.yml'
    @index_html     = Output.file '/../cache/raw/organization/index.html'
    @bonus_html     = Output.file '/../cache/raw/organization/bonus.html'
   # @pull_log       = Output.file '/../cache/raw/source/pull_log.yml'
    super
  end

  protected

  def get_metadata(doc)
	metadata=[]
	links_blocks=doc.xpath('//a[@class="bodylinks"]')

	links_blocks.each do |link_block|
			name=U.single_line_clean(link_block.inner_text)
      link=URI.unescape(link_block["href"])

      link="http://michigan.gov"+link
			metadata<<{
				:name=>name,
				:href=>link,
			}
	end
  #Adds organizations that are not included in the organization page but are used as sources
  #for the source page.
  append_bonus_orgs(metadata)
	metadata	
  end

# Returns as many fields as possible:
  #
  #   property :name
  #   property :names
  #   property :acronym
  #   property :org_type
  #   property :description
  #   property :slug
  #   property :url
  #   property :interest
  #   property :level
  #   property :source_count
  #   property :custom
  #
  def parse_metadata(metadata)
	{
      :name         => metadata[:name],
      :url          => metadata[:href],
      :catalog_name => "michigan.gov",
      :catalog_url  => @base_uri,
      :org_type     => "governmental",
      :organization => { :name => "Michigan" },

	}
  end

  private

  def append_bonus_orgs(metadata)
      doc = U.parse_html_from_file_or_uri(@bonus_uri, @bonus_html, :force_fetch => true)
      paragraphs=doc.xpath("//p[@style='padding-left: 7pt; text-indent: -8pt; margin-bottom: 0; margin-top: 0;']")

      paragraphs.each do |p|
        a_tag=p.css("a").first
        link=a_tag["href"]
        #If local link make appropraite changes
        link="http://michigan.gov"+link if link.match(/^\//)
        #Add http:// if it isn't there
        link="http://"+link if link.match(/^http:\/\//).nil?
     
        url=link.scan(/^http:\/\/.*?\//).first
        org_name=url.gsub("http://","").chop
        
        match=metadata.find {|m| url==m[:href]}
        metadata<<{:name=>org_name,:href=>url} if match.nil?
      end
  end
end
