#!/bin/bash
awslocal s3 mb s3://test-bucket
awslocal s3 cp /tmp/sample-data.csv s3://test-bucket/csv/sample-data.csv