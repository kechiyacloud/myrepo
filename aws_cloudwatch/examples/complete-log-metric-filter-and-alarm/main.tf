provider "aws" {
  region = "eu-west-1"
}

module "aws_sns_topic" {
  source = "https://github.com/cloud-destinations/cd-terraform-modules/tree/main/aws_sns?ref=b0f1334f17e6dd025f34d9879982a6cef3dab0ac"
}

module "log_group" {
  source = "../../modules/log-group"

  name_prefix = "my-app-"
}

locals {
  metric_transformation_name      = "ErrorCount"
  metric_transformation_namespace = "MyAppNamespace"
}

module "log_metric_filter" {
  source = "../../modules/log-metric-filter"

  log_group_name = module.log_group.cloudwatch_log_group_name

  name    = "metric-${module.log_group.cloudwatch_log_group_name}"
  pattern = "ERROR"

  metric_transformation_namespace = local.metric_transformation_namespace
  metric_transformation_name      = local.metric_transformation_name
}

module "alarm" {
  source = "https://github.com/terraform-aws-modules/terraform-aws-cloudwatch/tree/master/modules/metric-alarm?ref=e62a3b725a4d696ba4cf2dd864d64b611834247e"

  alarm_name          = "log-errors-${module.log_group.cloudwatch_log_group_name}"
  alarm_description   = "Log errors are too high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 10
  period              = 60
  unit                = "Count"

  namespace   = local.metric_transformation_namespace
  metric_name = local.metric_transformation_name
  statistic   = "Sum"

  alarm_actions = [module.aws_sns_topic.sns_topic_arn]
}
