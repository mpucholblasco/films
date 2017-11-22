#!/bin/bash

docker run -v $PWD/initial-data:/initial-data -v $PWD/config:/etc/mysql/conf.d -e MYSQL_ROOT_PASSWORD=rankdom1234 -p 3306:3306 -d mysql:5.6.34
