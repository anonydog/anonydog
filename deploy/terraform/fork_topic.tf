locals {
    anonydog_aws_tags = {
        "project"   = "anonydog",
        "anonydog"  = ""
    }
}

# topic for repo fork requests
resource "aws_sns_topic" "fork_topic" {
    name = "anonydog-fork-topic"
    tags = local.anonydog_aws_tags
}

# topic for retrying failed github repo webhook registrations
resource "aws_sns_topic" "webhook_topic" {
    name = "anonydog-webhook-topic"
    tags = local.anonydog_aws_tags
}

resource "aws_sns_topic_subscription" "fork_webhook_subscription" {
    topic_arn = aws_sns_topic.fork_topic.arn
    endpoint  = "https://${vercel_project.fork_webhook.name}.vercel.app/api/fork"

    protocol  = "https"
    endpoint_auto_confirms = true
}

resource "aws_sns_topic_subscription" "fork_webhook_webhook_retry_subscription" {
    topic_arn = aws_sns_topic.webhook_topic.arn
    endpoint  = "https://${vercel_project.fork_webhook.name}.anonydog.vercel.app/api/hookretry"

    protocol  = "https"
    endpoint_auto_confirms = true
}

resource "aws_sfn_state_machine" "retry_webhook_state_machine" {
  name     = "anonydog-webhook-state-machine"
  role_arn = aws_iam_role.sns_role.arn

  # thanks to https://alestic.com/2019/05/aws-delayed-sns-step-functions/
  definition = <<EOF
{
  "StartAt": "Delay",
  "Comment": "Publish to SNS with delay",
  "States": {
    "Delay": {
      "Type": "Wait",
      "SecondsPath": "$.delay_seconds",
      "Next": "Publish to SNS"
    },
    "Publish to SNS": {
      "Type": "Task",
      "Resource": "arn:aws:states:::sns:publish",
      "Parameters": {
        "TopicArn": "${ aws_sns_topic.webhook_topic.arn }",
        "Message.$": "$.message"
      },
      "End": true
    }
  }
}
EOF
}

resource "aws_iam_user" "sns_user"  {
    name = "AnonydogSNSUser"
    tags = local.anonydog_aws_tags
}

resource "aws_iam_role" "sns_role" {
    name = "AnonydogSNSRole"

    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": "${ aws_iam_user.sns_user.arn }"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "sns_policy" {
    name = "AnonydogSNSPolicy"
    role = aws_iam_role.sns_role.id

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
                "${ aws_sns_topic.fork_topic.arn }",
                "${ aws_sns_topic.webhook_topic.arn }"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "states:StartExecution"
            ],
            "Resource": [
                "${ aws_sfn_state_machine.retry_webhook_state_machine.arn }"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_access_key" "sns_access_key" {
    user = aws_iam_user.sns_user.name
}
