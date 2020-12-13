# @summary
#   Prepare the root CA for issuing signing CAs
#
class selfsigned::root_ca (
  $dir = regsubst($selfsigned::id, ' ','_', 'G'),
  $certificate      = "./${dir}/ca.crt",            # The CA cert
  $private_key      = "./${dir}/private/cakey.pem", # CA private key
  $serial           = "./${dir}/db/crt.srl",        # Serial number file
  $crlnumber        = "./${dir}/db/crl.srl",        # CRL number file
  $database         = "./${dir}/db/certificate.db", # Index file
  $new_certs_dir    = "./${dir}/archive",           # Certificate archive
  $unique_subject   = 'yes',                        # Require unique subject
  $default_md       = 'sha256',                     # MD to use
  $policy           = 'match_pol',                  # Default naming policy
  $email_in_dn      = 'no',                         # Add email to cert DN
  $preserve         = 'no',                         # Keep passed DN ordering
  $name_opt         = '$name_opt',                  # Subject DN display options
  $cert_opt         = 'ca_default',                 # Certificate display options
  $copy_extensions  = 'copy',                       # Copy extensions from CSR
  $x509_extensions  = 'signing_ca_ext',             # Default cert extensions
  $default_crl_days = '7',                          # How long before next CRL
  $crl_extensions   = 'crl_ext',                    # CRL extensions
) {
  # the relative path from the base directory of all things ssl, i.e. /etc/ssl usually

  file { "${selfsigned::ca_root}/${dir}":
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
  }

  -> file { [
    "${selfsigned::ca_root}/${dir}/private",
    "${selfsigned::ca_root}/${dir}/db",
    "${selfsigned::ca_root}/${dir}/archive",
  ]:
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0700',
  }

  file { "${selfsigned::ca_root}/openssl.cnf":
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0444',
    content => template('selfsigned/conf/ca.conf.erb'),
  }

  file { "${selfsigned::ca_root}/create-root-ca.bash":
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0555',
    content => template('selfsigned/bin/create-root-ca.bash.erb'),
  }

  # As we're rolling our own in (usually) /etc/systemconfig, let's give the original location a pointer...
  file { '/etc/ssl/openssl.cnf':
    ensure => link,
    force  => true,
    target => "${selfsigned::ca_root}/openssl.cnf",
  }
  file { "/etc/ssl/${dir}":
    ensure => link,
    force  => true,
    target => "${selfsigned::ca_root}/${dir}",
  }

}