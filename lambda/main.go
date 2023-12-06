package main

import (
	"lamba/internal"

	"github.com/aws/aws-lambda-go/lambda"
)

func main() {
	lambda.Start(internal.Handler)
}
