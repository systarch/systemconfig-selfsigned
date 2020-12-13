# @summary
#   Prepare everything for creating signing CA
#
define selfsigned::signing_ca (
  $common_name      = $name,
  $issuer           = $selfsigned::id,
  $certificate      = "./${name}/ca.crt",            # The CA cert
  $private_key      = "./${name}/private/cakey.pem", # CA private key
  $serial           = "./${name}/db/crt.srl",        # Serial number file
  $crlnumber        = "./${name}/db/crl.srl",        # CRL number file
  $database         = "./${name}/db/certificate.db", # Index file
  $new_certs_dir    = "./${name}/archive",           # Certificate archive
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
  $conf_template    = 'selfsigned/conf/signing.conf.erb',
) {
  # the relative path from the base directory of all things ssl, i.e. /etc/ssl usually

  file { "${selfsigned::ca_root}/${name}":
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
  }

  -> file { [
    "${selfsigned::ca_root}/${name}/private",
    "${selfsigned::ca_root}/${name}/db",
    "${selfsigned::ca_root}/${name}/archive",
  ]:
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0700',
  }

  file { "${selfsigned::ca_root}/${name}.openssl.cnf":
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0444',
    content => template('selfsigned/conf/signing.conf.erb'),
  }

  file { "${selfsigned::ca_root}/${name}/create-signing-ca.bash":
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0555',
    content => template('selfsigned/bin/create-signing-ca.bash.erb'),
  }
}