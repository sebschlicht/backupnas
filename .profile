# run anacron in user mode
/usr/sbin/anacron -s -t "${HOME}/etc/anacrontab" -S "${HOME}/var/spool/anacron"
