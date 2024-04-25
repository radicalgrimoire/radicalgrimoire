Redmine::OmniAuthSAML::Base.configure do |config|
  config.saml = {
    :assertion_consumer_service_url => "http://localhost:10083/auth/saml/callback", # OmniAuth callback URL
    :issuer                         => "http://localhost:10083",      # The issuer name / entity ID. Must be an URI as per SAML 2.0 spec.
    :single_logout_service_url      => "http://localhost:10083/auth/saml/sls",      # The SLS (logout) callback URL
    :idp_sso_target_url             => "https://login.microsoftonline.com/ec5c9760-1e1d-4de3-a9ff-c2fcf61d617f/saml2", # SSO login endpoint
    :idp_cert_fingerprint           => "27:0D:D6:8C:E9:9B:6D:D6:B0:47:F0:86:9F:99:50:92:DC:C4:64:50", # SSO ssl certificate fingerprint
    # Alternatively, specify the full certifiate:
    #:idp_cert                       => "-----BEGIN CERTIFICATE-----\n...\n-----END CERTIFICATE-----",
    :name_identifier_format         => "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent",
    :signout_url                    => "http://sso.example.com/saml2/idp/SingleLogoutService.php?ReturnTo=", # Optional signout URL, not supported by all identity providers
    :idp_slo_target_url             => "http://localhost:10083/auth/saml/sls",
    :name_identifier_value          => "mail", # Which redmine field is used as name_identifier_value for SAML logout
    :attribute_mapping              => {
    # How will we map attributes from SSO to redmine attributes
      :login      => 'extra raw_info http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name',
      :mail       => 'extra raw_info http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name',
      :firstname  => 'extra raw_info http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname',
      :lastname   => 'extra.raw_info.http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname'
    }
  }

  config.on_login do |omniauth_hash, user|
    # Implement any hook you want here
  end
end
