#!/bin/bash

# Startup-Script Re-run Controlled based on Custom Metadata Value - [run-startup-script (yes/no)]

# Function to get Metadata Response
get_metadata_response(){
	metadata_baseurl='http://metadata.google.internal/computeMetadata/v1/'
	metadata_header='Metadata-Flavor: Google'
	metadata_entry=$1
	
	# Required Metadata URL
	req_metadata_url=$metadata_baseurl$metadata_entry
	
	metadata_response=`curl -s -o /dev/null -w "%{http_code}" $req_metadata_url -H "$metadata_header"`
	
	echo $metadata_response
}

# Function to get Metadata Value
get_metadata_value(){
	metadata_baseurl='http://metadata.google.internal/computeMetadata/v1/'
	metadata_header='Metadata-Flavor: Google'
	metadata_entry=$1
	
	# Required Metadata URL
	req_metadata_url=$metadata_baseurl$metadata_entry
	
	metadata_value=`curl -s $req_metadata_url -H "$metadata_header"`
	
	echo $metadata_value
}

# Get Instance Name and Zone from Metadata
instance_name_url='instance/name'
instance_zone_url='instance/zone'

instance_name=$(get_metadata_value $instance_name_url)
instance_zone=$(get_metadata_value $instance_zone_url | cut -d/ -f4)

# Check if Custom Metadata run-startup-script exist and set it if it does not with run-startup-script value as "yes"
run_script_metadata_url='instance/attributes/run-startup-script'
run_script_metadata_response=$(get_metadata_response $run_script_metadata_url)
if [ "$run_script_metadata_response" -eq 404 ]; # Custom Metadata run-startup-script does not exist
then
gcloud compute instances add-metadata $instance_name --zone $instance_zone --metadata=run-startup-script=yes --quiet
fi

# Check if Custom Metadata run-startup-script value is set to "yes" and set it to "no" once execution is completed
run_script_metadata_value=$(get_metadata_value $run_script_metadata_url)
if [ "$run_script_metadata_value" = "yes" ];
then

# --------------------- START Startup-Script ------------------------

apt-get update
apt-get install -y apache2

# --------------------- END Startup-Script ---------------------------

gcloud compute instances add-metadata $instance_name --zone $instance_zone --metadata=run-startup-script=no --quiet
else
 echo "Skipping Startup-Script as Custom Metadata run-startup-script is set to no"
fi