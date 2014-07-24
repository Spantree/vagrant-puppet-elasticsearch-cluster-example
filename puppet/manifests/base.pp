$nodes = hiera('nodes', false)

$es_settings = hiera('elasticsearch', false)

$floored_heap = floor($memorysize_mb * 0.6)

notify { $nodes[$hostname]['fqdn']: }

include java7

$elasticsearch_publish_host = $vm_type ? {
  'vagrant' => $ipaddress_eth1,
  default   => $ipaddress_eth0
}

class { 'elasticsearch':
  package_url => "https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-${es_settings['version']}.deb",
  init_defaults => {
    'ES_HEAP_SIZE' => "${floored_heap}m"
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
      publish_host => $elasticsearch_publish_host
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
        enabled => $enable_marvel_agent
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

# username: elasticsearch
# password: admin
htpasswd { 'elasticsearch':
  cryptpasswd => "$apr1$Qy54BjRt$2yrD.Y8vY3jOkvDhLq/Tj/",
  target      => '/etc/nginx/.htpasswd',
  require     => Class['nginx']
}

file { "/etc/nginx/.htpasswd":
  owner => "nginx",
  group => "nginx",
  require => Htpasswd['elasticsearch']
}


