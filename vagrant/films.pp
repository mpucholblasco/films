# Passwords
$mysql_root_password = 'mystrongpassword'
$mysql_films_password = 'filmspassword'
$films_secret_key_base = '8f341fa7b279b541e0240983cf9a7e69bb8ee72891bcdb76ed6d0282013822ea171315808b5f2db46aa5d23f9adf9a2c655592c01962b38a6a4d1a74049844f8'

# Configure APT
class { 'apt':
  always_apt_update    => false,
  apt_update_frequency => 'daily',
}

class { 'apt::release':
  release_id => 'precise',
}

apt::ppa { 'ppa:brightbox/ruby-ng': }

apt::source { 'passenger':
        location => 'https://oss-binaries.phusionpassenger.com/apt/passenger',
        repos => 'main',
        key => '561F9B9CAC40B2F7',
        key_server => 'keyserver.ubuntu.com'
}

# Install packages
package { ['ruby2.1','ruby2.1-dev','ruby-switch']:
	ensure => latest,
	require => Apt::Ppa['ppa:brightbox/ruby-ng']
} ->
package { 'bundler':
	ensure => latest,
	provider => 'gem'
}

# Required to install films
package { ['git', 'libmysqlclient-dev', 'nodejs' ]: }

# MySQL database
class { '::mysql::server':
	root_password => $mysql_root_password,
}

mysql::db { 'films':
	user => 'films',
	password => $mysql_films_password,
	charset => 'utf8',
	collate => 'utf8_general_ci',
	host => 'localhost',
	grant => [ 'ALL' ]
}

# Install and configure 'films'
file { '/usr/share/films':
	ensure => 'directory'
}

vcsrepo { '/usr/share/films':
	ensure => present,
	provider => git,
	source => 'git://github.com/mpucholblasco/films.git',
	require => [ Package['git'], Class['apache'] ],
	notify => Exec['install-bundles'],
	owner => 'www-data',
	group => 'www-data'
} ->
file { '/usr/share/films/config/database.yml':
	ensure => present,
	content => template("database.yml.erb"),
	owner => 'www-data',
	group => 'www-data'
} ->
file { '/usr/share/films/config/secrets.yml':
	ensure => present,
	content => template("secrets.yml.erb"),
	owner => 'www-data',
	group => 'www-data',
} ->
exec { 'films-generate-db':
        path => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
        cwd => '/usr/share/films',
	command => 'rake db:migrate RAILS_ENV=production',
	require => Mysql::Db['films'],
	onlyif => "/usr/bin/test \"x`/usr/bin/mysql --defaults-extra-file=/root/.my.cnf --skip-column-names --batch -A -e \"SELECT count(1) from information_schema.TABLES where TABLE_SCHEMA = 'films';\"`\" == \"x0\""
} ->
exec { 'precompile-assets':
	creates => '/usr/share/films/public/assets',
        path => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
        cwd => '/usr/share/films',
	command => 'rake assets:precompile',
	require => Package['nodejs'] 
}

exec { 'install-bundles':
	path => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
	cwd => '/usr/share/films',
	command => 'bundle install',
	refreshonly => true,
	require => [ Package['libmysqlclient-dev'], Package['bundler'] ]
}

#exec { 'chown-films':
#	path => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
#	command => 'chown -R www-data:www-data /usr/share/films',
#	require => Vcsrepo['/usr/share/films']
#}

# Install apache
class { 'apache':
  default_mods        => false,
  default_confd_files => false,
}

class { 'apache::mod::passenger':
	passenger_root => '/usr/lib/ruby/vendor_ruby/phusion_passenger/locations.ini'
}

apache::vhost { 'films':
	port => '80',
	docroot => '/usr/share/films/public',
	priority => 10,
	options => ['-MultiViews'],
}
