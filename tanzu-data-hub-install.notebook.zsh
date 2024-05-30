#reference document https://docs.vmware.com/en/Tanzu-Data-Hub/1.0.0/tdh/install.html 

#login pivnet cli with your api token
export $PIVNET_TOKEN='your_token'
pivnet login --api-token=$PIVNET_TOKEN

#download data hub installer from pivnet

pivnet download-product-files --product-slug='vmware-tanzu-data-hub' --release-version='1.0.0' --product-file-id=1784004

#install downloaded file
sudo install tdh-darwin-arm64 /usr/local/bin/tdh-installer

#kickstart the installation and bring up your default broweser
tdh-installer install --ui

########SAMPLE CONFIG FILE#########
EnvironmentDetails:
Environment: env_name
StorageClass: storage_class_name_with_read_write_many_permission
Provider: tkg_or_openshift
Kubeconfig:
# We can skip kubeConfig in case of tkg and provide VSphereDetails section
Kubeconfig: kubeconfig_goes_here
VSphereDetails:
username: "vcenter_username_if_kubeconfig_not_provided"
password: "vcenter_password_if_kubeconfig_not_provided"
fqdn: "vcenter_fqdn_if_kubeconfig_not_provided"
VSphereNamespace: "vshpere_namespace_if_kubeconfig_not_provided"
tkgClusterName: "tkgClusterName_if_kubeconfig_not_provided"
CertificateDetails:
generateSelfSignedCert: true
# If generateSelfSignedCert: false, enter all the three certificateCA, certificateKey, certificateBody
# Enter idpIp, operationQueueIp and controlPlaneIp in case you want to provide custom IP for the exposed services
certificateCA:
certificateKey:
certificateBody:
# Certificate Domain Should be wildcard certificate domain. Ex - *.tdh.broadcom.com
certificateDomain: "wildcard_certificate_domain_goes_here"
idpIp: ""
operationQueueIp: ""
controlPlaneIp: ""
SmtpDetails:
# In case isInternal: false, then enter host, port, from, username, password, tlsEnabled and authEnabled
# In case isInternal: true, then no need to enter host, port, from, username, password, tlsEnabled and authEnabled
host: smtp_host_goes_here
port: smtp_port_goes_here
from: smtp_from_goes_here
username: smtp_username_goes_here
password: smtp_password_goes_here
tlsEnabled: true_or_false
authEnabled: true_or_false
isInternal: false
SreLoginDetails:
username: sre_user_email_goes_@here
password: sre_user_password_goes_here
ImageRegistryDetails:
isAirGapped: true_or_false
registryType: "JFrog_or_Harbor_or_GoogleArtificatsRegistry"
# If isAirGapped: false, provide registryUrl else we can omit that field
registryUrl: registry_url_goes_here
registryCreds: image_registry_creds_goes_here
########SAMPLE CONFIG FILE ended #########

#only Vsphere with Tanzu and Openshift support on 30 May 2024 Experiment adjoured

