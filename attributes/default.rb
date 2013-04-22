# List of mirrors:  http://www.openbsd.org/ftp.html#ftp
default['openbsd']['pkg_path'] = "http://ftp.iij.ad.jp/pub/OpenBSD/#{kernel['release']}/packages/#{kernel['machine']}/"
