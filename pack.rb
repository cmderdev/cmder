# Samuel Vasko 2013
# Cmder packing script -- Creates zip files for relase

require "fileutils"

def create_archive name, exclude
    if exclude
        exclude = " -x!" + exclude
    else
        exclude = ""
    end
    puts "Running 7z a -x@cmder\\packignore" + exclude + " " + name + " cmder"
    system("7z a -x@cmder\packignore + "+ name +" cmder")
end

targets = [
    ["cmder.zip"],
    ["cmder.7z"],
    ["cmder_mini.zip", "vendor\\msysgit"]
]

unless system("git describe --abbrev=0 --tags")
    puts "Failied to get the last tag from git, looks like something is missing"
end

version = `git describe --abbrev=0 --tags`
FileUtils.touch('Version ' + version)

targets.each do |ar|
    create_archive ar[0], ar[1]
end

FileUtils.rm('Version ' + version)

