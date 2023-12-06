#!/usr/bin/env bash
set -eio pipefail

bucket=cloud-coding-challenge-bucket
key=`head -c 32 < /dev/urandom | base64 | cut -c "1-10" | tr -cd '[:alnum:]._-'`
key_file="${key}.json"

# This test script assumes that the infra+app has been deployed

# Generate a JSON file with a list of random numbers
echo "⭐️ Generating random numbers... (also deleting any existing random_numbers.json file)"

rm -f "${key_file}" || true
echo -n "[" >> $key_file

numbers=()
expected_sum=0
for i in {1..10}
do
    number=$RANDOM
    numbers+=($number)
    expected_sum=$((expected_sum + number))
    echo -n $number >> $key_file
    if [ $i -ne 10 ]
    then
        echo -n ", " >> $key_file
    fi
done
echo -n "]" >> $key_file

echo "⭐️ Expected sum: ${expected_sum}"

# Upload the JSON file to S3
echo "⭐️ Uploading random_numbers.json to S3..."
aws s3api put-object --bucket "${bucket}" --key "${key}.json" --body "${key_file}" > /dev/null

echo -n "⭐️ Sleeping for 10 seconds to allow the lambda to process the file"
for i in {1..10}
do
    echo -n "."
    sleep 1
done
echo ""


# Check the logs for the expected sum
echo "⭐️ Checking the latest log stream for the expected sum..."

log_group="/aws/lambda/cloud-coding-challenge-lambda"
latest_log_stream=$(aws logs describe-log-streams --log-group-name $log_group | 
    jq -r '.logStreams |
    sort_by(.creationTime) |
    reverse |
    .[0]')
latest_log_stream_name=$(echo $latest_log_stream | jq -r '.logStreamName')
logs=$(aws logs get-log-events --log-group-name $log_group --log-stream-name $latest_log_stream_name | 
    jq -r '.events[].message')

#Prematurely clean up, since we're not sure how this script exits
aws s3api delete-object --bucket "${bucket}" --key "${key_file}" > /dev/null
rm -f "${key_file}" || true

if [[ $logs != *"Sum: ${expected_sum}"* ]]
then
    echo "❌ Test failed"
    exit 1
fi

echo "✅ Test passed"


