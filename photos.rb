require 'csv'
require 'open-uri'
require 'twitter'


def make_filename candidate
    "#{candidate['office']}-#{candidate['name']}"
    .gsub(' ','-').gsub(/[^a-zA-Z0-9\-]/,'')
end

def grab_photo(person, field='photo')
    if person[field]
        unless File.exists?(person[field])
            photo = retrieve_from_url person, person[field]
            person[field] = photo || nil
        end
    end
    retrieve_from_facebook person if person['faceook'] && person['photo'].nil?
    retrieve_from_twitter person if person['twitter'] && person['photo'].nil?
end

def retrieve_from_url(person, path)

    ext = path.split('.').last.split(/\?|#/).first
    ext = 'jpg' if ext.length > 4

    filename = make_filename person
    filename = "images/candidates/#{filename}.#{ext}"

    return filename if File.exists?(filename)

    begin
        open(path, 'User-Agent' => 'ruby') do |remote_file|
            if remote_file.length > 0
                File.open(filename, "wb") do |local_file|
                    local_file.puts remote_file.read
                end
                return filename
            end
        end
    rescue => e
        puts "Could not open #{path} for #{person['name']}"
    end
    return false
end

def retrieve_from_facebook person
    facebook_page_name = person['facebook'].split(/\?|#/).first
    facebook_page_name = person['facebook'].split('/').last

    graph_endpoint = ("http://graph.facebook.com/#{facebook_page_name}"+
                      "/picture?redirect=true")
    photo = retrieve_from_url person, graph_endpoint
    person['photo'] = photo if photo
end

twitter_client = nil

def retrieve_from_twitter person
    if twitter_client.nil?
        twitter_client = Twitter::REST::Client.new do |config|
          config.consumer_key        = "EGYNtJkjYbESmbUPGBHZCA"
          config.consumer_secret     = "TXlCXQfIYu2aLiUgo2GfmAj78DNt6JVQmxjhOM"
          config.access_token        = "14759621-lwHJpacKaBNy7ha5tRJccHAVjYoW6EOV54F5uiddw"
          config.access_token_secret = "xqTzCIGK4DVgW1J9sUQLqPuF5NCMnLGOpMEengNjsQ"
          # I've expired these
        end
    end

    begin
        # Get photo from twitter
        begin
            user = twitter_client.user( person['twitter'].split('/').last )
            photo = grab_photo person, user.profile_image_url.to_s.gsub('_normal','')
            person['photo'] = photo if photo
        rescue Twitter::Error::NotFound => error
            person['twitter'] = nil
        end
    rescue Twitter::Error::TooManyRequests => error
    end
end
