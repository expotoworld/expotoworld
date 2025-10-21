# Makefile for auth-cleanup-lambda
# Requires: Go 1.22+, AWS CLI v2, zip

REGION              ?= eu-central-1
ACCOUNT_ID          ?= $(shell aws sts get-caller-identity --query Account --output text 2>/dev/null)

FUNC_DEV            ?= expotoworld-auth-cleanup-dev
FUNC_PROD           ?= expotoworld-auth-cleanup-prod

# Secrets Manager ARNs that hold { "DATABASE_URL": "..." }
# Configure these before running update-config targets
SECRET_ARN_DEV      ?= arn:aws:secretsmanager:eu-central-1:834076182408:secret:expotoworld/neon/dev_auth-cleaner-nO64KK
SECRET_ARN_PROD     ?= arn:aws:secretsmanager:eu-central-1:834076182408:secret:expotoworld/neon/prod_auth-cleaner-iv3ynA

# Optional configuration
METRIC_NAMESPACE    ?= ExpoToWorld/AuthCleanup
STATEMENT_TIMEOUT_MS?= 10000
TIMEOUT_SECONDS     ?= 30
MEMORY_SIZE_MB      ?= 128

# Optional alarm/SNS
ALARM_ACTIONS_ARN   ?=

.PHONY: build package clean deploy-dev deploy-prod update-config-dev update-config-prod \
        rule-dev allow-dev target-dev rule-prod allow-prod target-prod \
        invoke-dev invoke-prod logs-dev logs-prod alarm-dev alarm-prod

build:
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o bootstrap

package: build
	zip -q -9 function.zip bootstrap

clean:
	rm -f bootstrap function.zip

# Update Lambda code only (function must already exist)
deploy-dev: package
	aws lambda update-function-code \
	  --region $(REGION) \
	  --function-name $(FUNC_DEV) \
	  --zip-file fileb://function.zip

deploy-prod: package
	aws lambda update-function-code \
	  --region $(REGION) \
	  --function-name $(FUNC_PROD) \
	  --zip-file fileb://function.zip

# Update Lambda configuration (env vars, timeout, memory)
update-config-dev:
	@[ -n "$(SECRET_ARN_DEV)" ] || (echo "ERROR: SECRET_ARN_DEV is empty" && exit 1)
	aws lambda update-function-configuration \
	  --region $(REGION) \
	  --function-name $(FUNC_DEV) \
	  --timeout $(TIMEOUT_SECONDS) \
	  --memory-size $(MEMORY_SIZE_MB) \
	  --environment "Variables={SECRET_ARN=$(SECRET_ARN_DEV),METRIC_NAMESPACE=$(METRIC_NAMESPACE),STATEMENT_TIMEOUT_MS=$(STATEMENT_TIMEOUT_MS),AWS_REGION=$(REGION)}"

update-config-prod:
	@[ -n "$(SECRET_ARN_PROD)" ] || (echo "ERROR: SECRET_ARN_PROD is empty" && exit 1)
	aws lambda update-function-configuration \
	  --region $(REGION) \
	  --function-name $(FUNC_PROD) \
	  --timeout $(TIMEOUT_SECONDS) \
	  --memory-size $(MEMORY_SIZE_MB) \
	  --environment "Variables={SECRET_ARN=$(SECRET_ARN_PROD),METRIC_NAMESPACE=$(METRIC_NAMESPACE),STATEMENT_TIMEOUT_MS=$(STATEMENT_TIMEOUT_MS),AWS_REGION=$(REGION)}"

# EventBridge: daily at 02:00 UTC
rule-dev:
	aws events put-rule \
	  --region $(REGION) \
	  --name $(FUNC_DEV) \
	  --schedule-expression "rate(12 hours)" \
	  --description "Auth cleanup every 12 hours (dev)"

allow-dev:
	aws lambda add-permission \
	  --region $(REGION) \
	  --function-name $(FUNC_DEV) \
	  --statement-id auth-cleanup-schedule-dev \
	  --action lambda:InvokeFunction \
	  --principal events.amazonaws.com \
	  --source-arn arn:aws:events:$(REGION):$(ACCOUNT_ID):rule/$(FUNC_DEV)

target-dev:
	aws events put-targets \
	  --region $(REGION) \
	  --rule $(FUNC_DEV) \
	  --targets "Id"="1","Arn"="arn:aws:lambda:$(REGION):$(ACCOUNT_ID):function:$(FUNC_DEV)"

rule-prod:
	aws events put-rule \
	  --region $(REGION) \
	  --name $(FUNC_PROD) \
	  --schedule-expression "rate(12 hours)" \
	  --description "Auth cleanup every 12 hours (prod)"

allow-prod:
	aws lambda add-permission \
	  --region $(REGION) \
	  --function-name $(FUNC_PROD) \
	  --statement-id auth-cleanup-schedule-prod \
	  --action lambda:InvokeFunction \
	  --principal events.amazonaws.com \
	  --source-arn arn:aws:events:$(REGION):$(ACCOUNT_ID):rule/$(FUNC_PROD)

target-prod:
	aws events put-targets \
	  --region $(REGION) \
	  --rule $(FUNC_PROD) \
	  --targets "Id"="1","Arn"="arn:aws:lambda:$(REGION):$(ACCOUNT_ID):function:$(FUNC_PROD)"

invoke-dev:
	aws lambda invoke --region $(REGION) --function-name $(FUNC_DEV) --payload '{}' /tmp/out-dev.json && cat /tmp/out-dev.json

invoke-prod:
	aws lambda invoke --region $(REGION) --function-name $(FUNC_PROD) --payload '{}' /tmp/out-prod.json && cat /tmp/out-prod.json

logs-dev:
	aws logs tail "/aws/lambda/$(FUNC_DEV)" --follow --region $(REGION)

logs-prod:
	aws logs tail "/aws/lambda/$(FUNC_PROD)" --follow --region $(REGION)

alarm-dev:
	@[ -n "$(ALARM_ACTIONS_ARN)" ] || (echo "WARN: ALARM_ACTIONS_ARN empty; creating alarm without actions" )
	aws cloudwatch put-metric-alarm \
	  --region $(REGION) \
	  --alarm-name $(FUNC_DEV)-Errors \
	  --metric-name Errors \
	  --namespace AWS/Lambda \
	  --dimensions Name=FunctionName,Value=$(FUNC_DEV) \
	  --statistic Sum --period 300 --evaluation-periods 1 --threshold 1 \
	  --comparison-operator GreaterThanOrEqualToThreshold \
	  --treat-missing-data notBreaching \
	  $(if $(ALARM_ACTIONS_ARN),--alarm-actions $(ALARM_ACTIONS_ARN),)

alarm-prod:
	@[ -n "$(ALARM_ACTIONS_ARN)" ] || (echo "WARN: ALARM_ACTIONS_ARN empty; creating alarm without actions" )
	aws cloudwatch put-metric-alarm \
	  --region $(REGION) \
	  --alarm-name $(FUNC_PROD)-Errors \
	  --metric-name Errors \
	  --namespace AWS/Lambda \
	  --dimensions Name=FunctionName,Value=$(FUNC_PROD) \
	  --statistic Sum --period 300 --evaluation-periods 1 --threshold 1 \
	  --comparison-operator GreaterThanOrEqualToThreshold \
	  --treat-missing-data notBreaching \
	  $(if $(ALARM_ACTIONS_ARN),--alarm-actions $(ALARM_ACTIONS_ARN),)

