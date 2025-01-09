#!/bin/bash
# This script is used to add environment variables to a Cloud Run service
# Create a .dockerenv file in the root directory of the project with the environment variables
# Modify the PROJECT_ID and CLOUD_RUN_SERVICE_NAME variables to match your project and service
# Run the script with the following command: ./add_env_to_cloud_run.sh


PROJECT_ID=""
CLOUD_RUN_SERVICE_NAME=""

# Set GCP project and quota project
echo "Setting GCP project and quota project to $PROJECT_ID"
gcloud auth application-default set-quota-project $PROJECT_ID
gcloud config set project $PROJECT_ID

# Check if .dockerenv file exists
if [ ! -f .dockerenv ]; then
    echo "Error: .dockerenv file not found"
    exit 1
fi

# Read .dockerenv file and format for gcloud command
echo "Reading .dockerenv file..."
ENV_VARS=""
while IFS='=' read -r key value; do
    # Skip empty lines and comments
    if [ -z "$key" ] || [[ $key == \#* ]]; then
        continue
    fi
    
    # Skip if key is empty
    if [ -z "$key" ]; then
        continue
    fi
    
    # Remove any whitespace from key
    key=$(echo "$key" | tr -d '[:space:]')
    
    # Skip if key contains invalid characters
    if [[ ! $key =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        echo "Warning: Skipping invalid environment variable name: $key"
        continue
    fi
    
    # Remove any surrounding quotes from the value
    value=$(echo "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
    
    if [ -n "$key" ] && [ -n "$value" ]; then
        if [ -z "$ENV_VARS" ]; then
            ENV_VARS="$key=$value"
        else
            ENV_VARS="$ENV_VARS,$key=$value"
        fi
    fi
done < .dockerenv

if [ -z "$ENV_VARS" ]; then
    echo "Error: No valid environment variables found in .dockerenv"
    exit 1
fi

echo "Prepared environment variables for update..."

# Update Cloud Run service with environment variables
echo "Updating environment variables for $CLOUD_RUN_SERVICE_NAME..."
gcloud run services update $CLOUD_RUN_SERVICE_NAME \
    --update-env-vars="$ENV_VARS" \
    --no-traffic \
    --platform managed \
    --region us-central1

if [ $? -eq 0 ]; then
    echo "Successfully updated environment variables for $CLOUD_RUN_SERVICE_NAME"
else
    echo "Failed to update environment variables"
    exit 1
fi