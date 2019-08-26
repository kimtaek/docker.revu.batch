#!/usr/bin/env bash
service mysql start
mysql -s -e "INSERT INTO mysql.user (host,user,password) VALUES ('%','root',password('root'));"
mysql -s -e "UPDATE mysql.user set password=password('root');"
mysql -s -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%';"
mysql -s -e "FLUSH PRIVILEGES;"
service mysql stop
service supervisor start