package internal

import (
	"context"
	"encoding/json"
	"io"
	"log"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

// Largely from example: https://docs.aws.amazon.com/lambda/latest/dg/with-s3-example.html
func Handler(ctx context.Context, s3Event events.S3Event) error {
	sdkConfig, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		log.Printf("failed to load default config: %s", err)
		return err
	}

	s3Client := s3.NewFromConfig(sdkConfig)

	// The could be of any event type,
	// but since we set up the events fired to the lambda function
	// to only be creation of objects events, we trust that and skip
	// any validation
	for _, record := range s3Event.Records {
		bucket := record.S3.Bucket.Name
		key := record.S3.Object.URLDecodedKey

		response, err := s3Client.GetObject(ctx, &s3.GetObjectInput{
			Bucket: &bucket,
			Key:    &key,
		})
		if err != nil {
			log.Printf("error getting object %s/%s: %s", bucket, key, err)
			return err
		}

		contents, err := io.ReadAll(response.Body)
		if err != nil {
			log.Printf("err when trying to read response from getting s3 object. Bucket = %s, Key = %s, Error = %s", bucket, key, err)
			return err
		}

		numbers := []int{}
		err = json.Unmarshal(contents, &numbers)
		if err != nil {
			log.Printf("Could not unmarshal json file. Contents: %s, error: %s", string(contents), err)
		}

		sum := 0
		for _, n := range numbers {
			sum += n
		}

		log.Printf("Successfully summed numbers! Bucket: %s, Key: %s, Sum: %d", bucket, key, sum)
	}

	return nil
}
