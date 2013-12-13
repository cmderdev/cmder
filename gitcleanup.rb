def main()
	git_dir = '\\vendor\\msysgit\\libexec\\git-core\\'
	working_dir = Dir.pwd
	Dir.chdir(working_dir + git_dir)
	Dir.entries(working_dir + git_dir).each do |file|
		if file == 'git.exe' or file == 'mergetools' or file.end_with?('.bat') then
			next
		end
		if file.end_with?('.exe') then
			File.open(File.basename(file, '.*') + '.bat', "w") do |new_file|
				new_file.write('@ECHO OFF\n' + File.basename(file, '.*').gsub('-',' ') + ' $*')
			end
			File.delete(file)
			next
		elsif file.end_with?('.bat') then
			File.open(file + '.bat', "w") do |new_file|
				new_file.write('@ECHO OFF\n' + file.gsub('-', ' ') + ' $*')
			end
			File.delete(file)
			next
		end
	end
end

main

