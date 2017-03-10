#!/bin/sh

export AWS_REGION=eu-west-1

rm -f ./privatekey.pem
aws s3 cp --region eu-west-1 s3://${CONFIG_BUCKET}/config/xero/privatekey.pem privatekey.pem
chmod 600 privatekey.pem
aws s3 cp --region eu-west-1 s3://${CONFIG_BUCKET}/config/xero/env.sh .
. ./env.sh
./xero-alert.rb
