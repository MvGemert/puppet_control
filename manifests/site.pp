include stdlib                       # Make sure the standard functions are available

$deployment_zone = lookup('deployment_zone', {default_value => 'undefined'})
#
#
schedule { 'maintenance':
  range  => "00:00 - 23:59"  # Change to your requirements
}

#
# Setup pki support prerequisites
# RETRIEVE REVERSE DOMAIN NAME 
#
$pki_files_location = lookup('pki_files_location', String[1])
$node_pki_files_location = lookup('pki_files_location', String[1])
# determine the directory to get the ssl certs from
$node_domainArray = reverse(split("$domain", '[.]'))
$node_reverseDomain = join($node_domainArray,'.')

lookup('role', {'merge' => unique,}).include
