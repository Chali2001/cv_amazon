resource "aws_dynamodb_table" "cv_visit_counter" {
  name         = "cv-visit-counter"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"

  attribute {
    name = "pk"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }
}

resource "aws_dynamodb_table_item" "initial_item" {
  table_name = aws_dynamodb_table.cv_visit_counter.name
  hash_key   = aws_dynamodb_table.cv_visit_counter.hash_key

  item = <<ITEM
{
  "pk": {"S": "visits"},
  "count": {"N": "0"}
}
ITEM
}
