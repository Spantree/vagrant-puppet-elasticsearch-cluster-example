$nodes = hiera('nodes', false)

$es_settings = hiera('elasticsearch', false)

notify { $nodes[$hostname]['fqdn']: }

include java7

class { 'elasticsearch':
  package_url => "https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-${es_settings['version']}.deb",
  init_defaults => {
    'ES_HEAP_SIZE' => "${memorysize_mb*0.6}"
  },
  status => enabled,
  config => {
    'node' => {
      name => $hostname
    },
    discovery => {
      zen => {
        ping => {
          multicast => {
            enabled => false
          },
          unicast => {
            hosts => $nodes[$hostname]['cluster_hosts']
          }
        }
      }
    },
    http => {
      max_content_length => '500mb'
    },
    network => {
      publish_host => $ipaddress_eth1
    },
    cluster => {
      name => $nodes[$hostname]['cluster'],
      routing => {
        allocation => {
          cluster_concurrent_rebalance => 2
        }
      }
    },
    marvel => {
      agent => {
        enabled => true
      }
    },
    bootstrap => {
      mlockall => true
    },
    indices => {
      fielddata => {
        cache => {
          size => '25%'
        }
      }
    },

  },
  require => Class['java7']
}

#this can be done on a single call
elasticsearch::plugin{'mobz/elasticsearch-head':
  module_dir  => 'head'
}

elasticsearch::plugin { 'elasticsearch/marvel/latest':
  module_dir  => 'marvel'
}

elasticsearch::plugin { 'lukas-vlcek/bigdesk':
  module_dir  => 'bigdesk'
}

class {'nginx': }
nginx::resource::upstream { 'elasticsearch':
  members => [
    'localhost:9200',
  ],
}
nginx::resource::vhost { $nodes[$hostname]['fqdn']:
  proxy => 'http://elasticsearch',
  listen_port => 80,
  auth_basic => "Restricted",
  auth_basic_user_file => "/etc/nginx/.htpasswd"
}
htpasswd { 'elasticsearch':
  cryptpasswd => "NOTSET",
  target      => '/etc/nginx/.htpasswd',
  require     => Class['nginx']
}

file { "/etc/nginx/.htpasswd":
  owner => "nginx",
  group => "nginx",
  require => Htpasswd['elasticsearch']
}


