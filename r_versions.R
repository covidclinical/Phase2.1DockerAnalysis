## print a diff'able record of installed packages and their versions
cat(paste(installed.packages()[, 1], installed.packages()[, 3]), sep = "\n")