#!/bin/bash

# This is sample code, for non-production usage. 
# You should work with your security and legal teams to meet your organizational security, regulatory and compliance requirements before deployment"

# Exit on any error
set -e

# Default values
STACK_NAME="iolink-demo-last-will-addon"

# Fix parameters
TEMPLATE_FILE="./last_will_addon.cfn.yaml"
REGION=$(aws configure get region)

# Function to print usage
usage() {
    echo "Usage: $0 -o <operation> -e <email>"
    echo "Operations:"
    echo "  c - Create new stack"
    echo "  u - Update existing stack"
    echo "  t - Terminate (delete) stack"
    echo "Email is required for create and update operations"
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

# Parse command line arguments
while getopts "o:e:" opt; do
    case $opt in
        o) OPERATION=$OPTARG ;;
        e) EMAIL=$OPTARG ;;
        *) usage ;;
    esac
done

# Check if operation is provided
if [ -z "$OPERATION" ]; then
    usage
fi

# Check if email is provided for create and update operations
if [[ "$OPERATION" =~ ^[cu]$ && -z "$EMAIL" ]]; then
    echo "Error: Email parameter is required for create and update operations"
    usage
fi

# Execute based on operation
case $OPERATION in
    c)
        echo "Creating new stack..."
        aws cloudformation create-stack \
            --stack-name "$STACK_NAME" \
            --template-body "file://$TEMPLATE_FILE" \
            --parameters ParameterKey=Email,ParameterValue="$EMAIL" \
            --capabilities CAPABILITY_IAM
        wait_for_stack_creation
        echo "Stack creation completed successfully!"
        ;;
    u)
        echo "Updating existing stack..."
        aws cloudformation update-stack \
            --stack-name "$STACK_NAME" \
            --template-body "file://$TEMPLATE_FILE" \
            --parameters ParameterKey=Email,ParameterValue="$EMAIL" \
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
