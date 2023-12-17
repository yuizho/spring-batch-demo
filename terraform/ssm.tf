resource "aws_ssm_document" "session_manager_run_shell" {
  // SSM-SessionManagerRunShell を設定するとAWS CLIを使う時にオプション指定を省略できる
  name = "SSM-SessionManagerRunShell"
  // type、format には session, json を指定する、SessionManager ではこの値は固定である
  document_type   = "Session"
  document_format = "JSON"

  content = <<EOF
    {
        "schemaVersion": "1.0",
        "description": "Document to hold regional settings for Session Manager",
        "sessionType": "Standard_Stream",
        "inputs": {
            "cloudWatchLogGroupName": "${aws_cloudwatch_log_group.ec2_ssm_operation.name}"
        }
    }
  EOF
}
