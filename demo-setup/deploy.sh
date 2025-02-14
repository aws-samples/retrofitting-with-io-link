#!/bin/bash


# This is sample code, for non-production usage. 
# You should work with your security and legal teams to meet your organizational security, regulatory and compliance requirements before deployment”

# Exit on any error
set -e

# Default values
STACK_NAME="iolink-demo"
ASSET_NAME="ice3"
ASSET_MODEL="IoLinkDemoModel"

# Fix paramters
TEMPLATE_FILE="./io-link-demo-resources.cfn.yaml"
REGION=$(aws configure get region)

# Function to print usage
usage() {
    echo "Usage: $0 -o <operation>"
    echo "Operations:"
    echo "  c - Create new stack"
    echo "  u - Update existing stack with existing parameter values"
    echo "  t - Terminate (delete) stack"
    exit 1
}

# Function to wait for stack creation
wait_for_stack_creation() {
    echo "Waiting for stack creation to complete..."
    aws cloudformation wait stack-create-complete --stack-name "$STACK_NAME"
    
    STATUS=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --query 'Stacks[0].StackStatus' --output text)
    if [ "$STATUS" != "CREATE_COMPLETE" ]; then
        echo "Stack creation failed with status: $STATUS"
        exit 1
    fi
}

# Function to wait for stack update
wait_for_stack_update() {
    echo "Waiting for stack update to complete..."
    aws cloudformation wait stack-update-complete --stack-name "$STACK_NAME"
    
    STATUS=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --query 'Stacks[0].StackStatus' --output text)
    if [ "$STATUS" != "UPDATE_COMPLETE" ]; then
        echo "Stack update failed with status: $STATUS"
        exit 1
    fi
}

# Function to wait for stack deletion
wait_for_stack_deletion() {
    echo "Waiting for stack deletion to complete..."
    aws cloudformation wait stack-delete-complete --stack-name "$STACK_NAME"
}

# Function to setup certificates
setup_certificates() {
    # Create directory for certificates if it doesn't exist
    mkdir -p certs
    cd certs

    # Get the private key from Secrets Manager
    echo "Downloading private key..."
    aws secretsmanager get-secret-value \
        --secret-id "$ASSET_NAME-private-key" \
        --query 'SecretString' \
        --output text > "$ASSET_NAME.pem.key"

    # Get the certificate from Parameter Store
    echo "Downloading certificate..."
    aws ssm get-parameter \
        --name "$ASSET_NAME-certificate" \
        --query "Parameter.Value" \
        --output text > "$ASSET_NAME.pem.cert"

    # Set appropriate permissions for the private key
    chmod 600 "$ASSET_NAME.pem.key"

    # Get the IoT endpoint
    echo "Getting IoT endpoint..."
    IOT_ENDPOINT=$(aws iot describe-endpoint --endpoint-type iot:Data-ATS --output text)

    echo "Setup complete!"
    echo "Certificate and private key are saved in the 'certs' directory"
    echo "IoT Endpoint: $IOT_ENDPOINT"
}

# Parse command line arguments
while getopts "o:" opt; do
    case $opt in
        o) OPERATION=$OPTARG ;;
        *) usage ;;
    esac
done

# Check if operation is provided
if [ -z "$OPERATION" ]; then
    usage
fi

# Execute based on operation
case $OPERATION in
    c)
        echo "Creating new stack..."
        aws cloudformation create-stack \
            --stack-name "$STACK_NAME" \
            --template-body "file://$TEMPLATE_FILE" \
            --parameters \
                ParameterKey=AssetName,ParameterValue="$ASSET_NAME" \
                ParameterKey=AssetModelName,ParameterValue="$ASSET_MODEL" \
                ParameterKey=LocationID,ParameterValue=$(uuidgen) \
                ParameterKey=DistanceMMID,ParameterValue=$(uuidgen) \
                ParameterKey=DistanceTransformID,ParameterValue=$(uuidgen) \
                ParameterKey=DistanceMetricID,ParameterValue=$(uuidgen) \
            --capabilities CAPABILITY_IAM
        wait_for_stack_creation
        setup_certificates
        echo "Stack creation completed successfully!"
        ;;
    u)
        echo "Updating existing stack with existing parameter values..."
        aws cloudformation update-stack \
            --stack-name "$STACK_NAME" \
            --template-body "file://$TEMPLATE_FILE" \
            --capabilities CAPABILITY_IAM
        wait_for_stack_update
        echo "Stack update completed successfully!"
        ;;
    t)
        echo "Terminating stack..."
        aws cloudformation delete-stack --stack-name "$STACK_NAME"
        wait_for_stack_deletion
        echo "Stack deletion completed successfully!"
        ;;
    *)
        echo "Invalid operation: $OPERATION"
        usage
        ;;
esac
