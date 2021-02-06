locals {
    anonydog_aws_tags = {
        "project"   = "anonydog",
        "anonydog"  = ""
    }
}
resource "aws_sns_topic" "fork_topic" {
    name = "anonydog-fork-topic"
    tags = local.anonydog_aws_tags
}

resource "aws_sns_topic_subscription" "fork_webhook_subscription" {
    topic_arn = aws_sns_topic.fork_topic.arn
    endpoint  = "https://${wercel_project.fork_webhook.name}.anonydog.vercel.app/api/fork"

    protocol  = "https"
    endpoint_auto_confirms = true
}

resource "aws_iam_user" "sns_user"  {
    name = "AnonydogSNSUser"
    tags = local.anonydog_aws_tags
}

resource "aws_iam_user_policy" "sqs_policy" {
    name = "AnonydogSNSPolicy"
    user = aws_iam_user.sns_user.name

    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sns:Publish"
            ],
            "Resource": [
                "${aws_sns_topic.fork_topic.arn}"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_access_key" "sns_access_key" {
    user = aws_iam_user.sns_user.name
}