CREATE DATABASE films_development;
CREATE USER `films`@'%' IDENTIFIED BY 'rankdom';
GRANT ALL PRIVILEGES ON films_development.* TO `films`@'%';
FLUSH PRIVILEGES;
