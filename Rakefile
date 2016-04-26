require 'csv'
require 'fileutils'
require 'json'
require 'webrick'

load 'controller.rb'
load 'photos.rb'

task :serve do
    port = ARGV[1] || 8080
    server = WEBrick::HTTPServer.new(:Port => port, :DocumentRoot => Dir.pwd)
    trap('INT') { server.shutdown }
    server.start
end

def csv_to_json filename
    list = []
    CSV.foreach("data/#{filename}.csv", :headers => true) do |row|
         list.push (Hash[row.headers.map(&:downcase).map(&:strip)
                    .zip(row.fields.map)])
    end
    File.open("data/#{filename}.json",'w') do |fl|
        fl.write(list.to_json)
    end
end
def download_csv_photos filename
    candidates = []

    Dir.mkdir 'images/candidates' unless Dir.exists?("images/candidates")

    CSV.foreach("data/#{filename}.csv", :headers => true) do |row|
        candidate = (Hash[row.headers.reject(&:nil?).map(&:downcase).map(&:strip)
                     .zip(row.fields.map)])
        grab_photo candidate, 'photo'
        candidates.push candidate
    end
    CSV.open("data/#{filename}.csv", "w") do |csv|
      csv << candidates.first.keys
      candidates.each do |candidate|
        csv << candidate.values
      end
    end
end
task :candidates do
    download_csv_photos 'candidates'
    csv_to_json 'candidates'
end
task :measures do
    csv_to_json 'measures'
end
task :erb, :paths do |t,args|
    """
    Rebuild HTML pages.
    """

    controller = Controller.new()

    args.paths.each do |path|
        new_file = path.gsub('.erb','')
        function_name = path.split('.').first

        puts "Rewriting #{new_file}"

        File.open(new_file, 'w') do |fl|
            controller.send(function_name) if controller.respond_to?(function_name)
            fl.write(controller.render(path))
        end
    end
end

task all: [:candidates] do
    """
    Rebuild all the HTML pages.
    """
    Rake::Task["erb"].invoke(Dir.glob("*.html.erb"))
    Rake::Task["sharing"].invoke()
end

task :sharing do
    candidates, _ = candidates_data

    build = {
        'candidates' => candidates,
    }

    FileUtils.rm_r 'sharing' if Dir.exists?("sharing")
    Dir.mkdir "sharing"

    build.each do |type, the_list|
        Dir.mkdir("sharing/#{type}") unless Dir.exists?("sharing/#{type}")

        the_list.each do |item|
            controller = Controller.new()
            controller.send(type, item)
            puts "Creating #{controller.filename}"
            File.open("sharing/#{controller.filename}.html", 'w') do |fl|
                fl.write(controller.render('sharing.erb'))
            end
        end
    end
end
