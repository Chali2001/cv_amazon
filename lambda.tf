data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_src"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "visit_counter" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "cv-visit-counter-function"
  role             = data.aws_iam_role.lab_role.arn
  handler          = "main.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.12"
}
