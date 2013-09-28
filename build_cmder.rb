# Samuel Vasko 2013
# Cmder build script
# Like really a beta

require 'FileUtils'
require "pp"

def get_file project, query
    # Should be changed to integrated downloader
    urlToFile = 'wget -q -O - "http://samuelvasko.tk/gcode/?project='+project+'&query='+query+'"'
    urlToFile = `#{urlToFile}`
    urlToFile =  urlToFile.split("\n").first

    extension = urlToFile.split('.').last
    filename = project+'.'+extension

    puts "\n ------ Downloading #{project} ------- \n \n"
    get_file = system("wget -O #{filename} -nc #{urlToFile}")

    unless get_file
        puts "Failied to download #{project} from #{urlToFile}"
        FileUtils.rm(filename) if File.exists?(filename)
        exit(1)
    end

    system("7z x -o\"#{project}\" #{project}.#{extension}")

    File.unlink(project+"."+extension);

    # When the folder contains another folder
    # that is not what we want
    if Dir.glob("#{project}/*").length == 1
        temp_name = "#{project}_temp"
        FileUtils.mv(project, temp_name)
        FileUtils.mv(Dir.glob("#{temp_name}/*")[0], project)
        FileUtils.rm_r(temp_name)
    end

end

puts '
______       _ _     _ _                                   _
| ___ \     (_) |   | (_)                                 | |
| |_/ /_   _ _| | __| |_ _ __   __ _     ___ _ __ ___   __| | ___ _ __
| ___ \ | | | | |/ _` | | \'_ \ / _` |   / __| \'_ ` _ \ / _` |/ _ \ \'__|
| |_/ / |_| | | | (_| | | | | | (_| |  | (__| | | | | | (_| |  __/ |
\____/ \__,_|_|_|\__,_|_|_| |_|\__, |   \___|_| |_| |_|\__,_|\___|_|
                                __/ |
                               |___/
'

puts 'Cleanup'

if Dir.exists?('vendor')
    Dir.glob('vendor/*') { |file| FileUtils.rm_rf(file) if File.directory?(file) }
end

Dir.chdir('vendor')

puts 'Getting files'

get_file('clink', 'label:Type-Archive label=Featured')
get_file('conemu-maximus5', 'label:Type-Archive label=Preview label=Featured')
get_file('msysgit', 'label:Type-Archive label:Featured')

puts 'Done, bye'
