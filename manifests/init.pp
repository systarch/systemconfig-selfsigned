# @summary
#   Install and setup of a self-signed CA system with root, intermediate, client and server certificates
#
class selfsigned (
  String $id,
  String $client_issuer_id,
  String $server_issuer_id,
  Stdlib::Unixpath $ca_root = '/etc/ssl', # Where all PKI things are located, usually /etc/systemconfig or /etc/ssl
  $domain   = $baseline::domain,
  $base_url = 'http://$domain/ca',        # CA base url
  $aia_url  = '$base_url/$ca.crt',        # CA certificate URL
  $crl_url  = '$base_url/$ca.crl',        # CRL distribution point
  $name_opt = 'multiline,-esc_msb,utf8',  # Display UTF-8 characters

  # [ ca_dn ]
  $common_name              = "${organization_name} Root CA",
  $country_name             = 'CH',
  $organization_name        = $baseline::organization_name,
  $state_or_province_name   = '',
  $locality_name            = '',
  $organizational_unit_name = '',
) {

  # Prepare the root CA for issuing signing CAs
  contain selfsigned::root_ca

  $subjects = $facts['inventory'].filter |$fqdn, $item| { $item['realm'] =~ /^dev\.systarch\.com$/ }

  # Prepare everything for a server signing CA and link all server subjects to it
  selfsigned::signing_ca { $server_issuer_id:
    common_name => "${organization_name} Server CA",
  }
  # Automatically create keys, csr, certificates for all subjects within the current system's realm
  $subjects.keys.each |$fqdn| {
    ensure_resource("selfsigned::server_certificate", $fqdn, { ensure => present })
  }

  # Prepare everything for a client signing CA and link all client subjects to it
  selfsigned::signing_ca { $client_issuer_id:
    common_name =>  "${organization_name} Client CA",
  }
  # Automatically create keys, csr, certificates for all subjects within the current system's realm
  $subjects.keys.each |$fqdn| {
    ensure_resource("selfsigned::client_certificate", $fqdn, {
      issuer_id          => $client_issuer_id,
       distinguished_name => {
        commonName => "root@${fqdn}",
      },
    })
  }

  # Create a CRL directory for all CA's
  file { "${selfsigned::ca_root}/crl":
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
  }

  # install a convenience script to generate the CRL information for the root CA
  file { '/usr/local/bin/selfsigned-crl-publish':
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0555',
    content => template('selfsigned/bin/crl-publish.bash.erb'),
  }
}
