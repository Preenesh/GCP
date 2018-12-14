#!/bin/bash

# Startup-Script to continue configuration after restart and Re-run Controlled based on Custom Metadata Value - [run-startup-script (yes/no)]

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
	# Check if Custom Metadata startup-script-step value is set and set it to step0 if not
	script_step_metadata_url='instance/attributes/startup-script-step'
	script_step_metadata_response=$(get_metadata_response $script_step_metadata_url)
	if [ "$script_step_metadata_response" -eq 404 ]; # Custom Metadata startup-script-step does not exist
	then
		gcloud compute instances add-metadata $instance_name --zone $instance_zone --metadata=startup-script-step=step0 --quiet
	fi
	# Check value of Custom Metadata startup-script-step value and run specific step
	script_step_metadata_value=$(get_metadata_value $script_step_metadata_url)
	
	case $script_step_metadata_value in
		step0)
				echo "Starting STEP - 0"
				# --------------------- START - Step 0 ------------------------
				apt-get update
				mkdir /demo
				touch /demo/step0.txt
				# --------------------- END - Step 0 --------------------------
				echo "Completed STEP - 0"
				# Set Script to the next step
				gcloud compute instances add-metadata $instance_name --zone $instance_zone --metadata=startup-script-step=step1 --quiet
				# Restart Server in 1 min
				init 6
				;;
		step1)
				echo "Starting STEP - 1"
				# --------------------- START - Step 1 ------------------------
				apt-get install -y apache2
				touch /demo/step1.txt
				# --------------------- END - Step 1 --------------------------
				echo "Completed STEP - 1"
				# Set Script to the next step
				gcloud compute instances add-metadata $instance_name --zone $instance_zone --metadata=startup-script-step=step2 --quiet
				# Restart Server in 1 min
				init 6
				;;
		step2)
				echo "Starting STEP - 2"
				# --------------------- START - Step 2 ------------------------
				apt-get update
				touch /demo/step2.txt
				# --------------------- END - Step 2 --------------------------
				echo "Completed STEP - 2"
				# Remove Script Step Metadata as it the last step
				gcloud compute instances remove-metadata $instance_name --zone $instance_zone --keys=startup-script-step --quiet
				# Set Script not to run at next reboot
				gcloud compute instances add-metadata $instance_name --zone $instance_zone --metadata=run-startup-script=no --quiet
				;;
	esac
else
	echo "Skipping Startup-Script as Custom Metadata run-startup-script is set to no"
fi