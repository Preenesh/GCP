#!/bin/bash

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

# Function to get Metadata
get_metadata_value(){
	metadata_baseurl='http://metadata.google.internal/computeMetadata/v1/'
	metadata_header='Metadata-Flavor: Google'
	metadata_entry=$1
	
	# Required Metadata URL
	req_metadata_url=$metadata_baseurl$metadata_entry
	
	metadata_value=`curl -s $req_metadata_url -H "$metadata_header"`
	
	echo $metadata_value
}


# Instance Name
'instance/name'

# Add instance metadata

VMNAME=$(curl -H Metadata-Flavor:Google http://metadata/computeMetadata/v1/instance/hostname | cut -d. -f1)
ZONE=$(curl -H Metadata-Flavor:Google http://metadata/computeMetadata/v1/instance/zone | cut -d/ -f4)
gcloud compute instances add-metadata $VMNAME --zone $ZONE --metadata=test1=yes --quiet
