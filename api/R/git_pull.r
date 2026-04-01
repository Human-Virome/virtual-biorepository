api_git_pull <- function () {
  
  odir <- setwd(dir = '/var/www/hvp')
  on.exit(setwd(dir = odir))
  
  system2('/usr/bin/git',  c('pull', 'origin', 'main'))
  system2('/usr/bin/sudo', c('/usr/sbin/apache2ctl', 'restart'))
}
