import os

def main():
	cwd = os.getcwd()
	os.chdir(cwd + '\\vendor\\msysgit\\libexec\\git-core\\')
	for file_ in os.listdir(cwd + '\\vendor\\msysgit\\libexec\\git-core\\'):
		if file_ == 'git.exe' or file_ == 'mergetools' or file_.endswith('.bat'):
			continue # Ignore main git exe, mergetools folder and already created batch files.
		if file_.endswith('.exe'):
			with open(os.path.splitext(file_)[0] + '.bat', 'w') as out:
				out.write('@ECHO OFF\n' + os.path.splitext(file_)[0].replace('-',' ') + ' $*')
			os.remove(file_)
			# print 'Cleaned out ' + file_
			continue
		else:
			with open(file_ + '.bat', 'w') as out:
				out.write('@ECHO OFF\n' + file_.replace('-', ' ') + ' $*')
			os.remove(file_)
			# print 'Cleaned out ' + file_
			continue
	pass

if __name__ == '__main__':
	main()
