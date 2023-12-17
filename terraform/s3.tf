resource "aws_s3_bucket" "csv_data_bucket" {
  bucket = "yuizho-csv-data-bucket"
}

resource "aws_s3_object" "csv_data_bucket_object" {
  key    = "csv/sample-data.csv"
  bucket = aws_s3_bucket.csv_data_bucket.id
  source = "sample-data.csv"
}
