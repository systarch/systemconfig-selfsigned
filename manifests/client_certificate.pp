define selfsigned::client_certificate(
  $issuer_id          = lookup({name => 'selfsigned::client_issuer_id', default_value => undef}),
  $common_name        = $name,
  $ensure             = present,
  $distinguished_name = {},
  $days               = "180",
) {
  $certificate_type = 'client'
  $ca_root = lookup({name => 'selfsigned::ca_root', default_value => '/etc/ssl'})
  $subject_dir = "${ca_root}/${name}"

  if $ensure == present {
    ensure_resource('file', $subject_dir, {
      ensure => directory,
      owner  => root,
      group  => root,
      mode   => '0755',
    })
  }

  # create a generator script for this fqdn and signing ca
  file { "${subject_dir}/create-${certificate_type}.bash":
    ensure  => ($ensure == present) ? {
      true    => file,
      default => absent,
    },
    owner   => root,
    group   => root,
    mode    => '0555',
    content => template('selfsigned/bin/create-certificate.bash.erb'),
  }

  # create the openssl.cnf for creating the certificate request
  file { "${subject_dir}/${certificate_type}.openssl.cnf":
    ensure  => ($ensure == present) ? {
      true    => file,
      default => absent,
    },
    owner   => root,
    group   => root,
    mode    => '0555',
    content => template("selfsigned/conf/${certificate_type}-certificate.conf.erb"),
  }
}