import boto3
import json
import os
from datetime import datetime

def lambda_handler(event, context):
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(os.environ.get('TABLE_NAME'))
    print(event)
    SnsPublishTime = event['Records'][0]['Sns']['Timestamp']
    SnsTopicArn = event['Records'][0]['Sns']['TopicArn']
    SESMessage = json.loads(event['Records'][0]['Sns']['Message'])

    SESMessageType = SESMessage['notificationType']
    SESMessageId = SESMessage['mail']['messageId']
    SESDestinationAddress = SESMessage['mail']['destination']
    LambdaReceiveTime = datetime.now();
    SESSourceAddress = SESMessage['mail']['source']
    SESSourceIP = SESMessage['mail']['sourceIp']
    SESSubject = SESMessage['mail']['commonHeaders']['subject']
    print(SESMessageId, SESDestinationAddress)

    if (SESMessageType == "Bounce"):
        SESreportingMTA = SESMessage['bounce']['reportingMTA']
        SESbounceSummary = json.dumps(SESMessage['bounce']['bouncedRecipients'])
        response = table.put_item(
            Item = {
                "SESMessageId": SESMessageId,
                "SnsPublishTime": SnsPublishTime,
                "SESreportingMTA": SESreportingMTA,
                "SESDestinationAddress": SESDestinationAddress,
                "SESSourceAddress": SESSourceAddress,
                "SESSourceIP": SESSourceIP,
                "SESSubject": SESSubject,
                "SESbounceSummary": SESbounceSummary,
                "SESMessageType": SESMessageType
            }
        )
    elif (SESMessageType == "Delivery"):
        SESsmtpResponse1 = SESMessage['delivery']['smtpResponse']
        SESreportingMTA1 = SESMessage['delivery']['reportingMTA']
        response = table.put_item(
            Item = {
                "SESMessageId": SESMessageId,
                "SnsPublishTime": SnsPublishTime,
                "SESsmtpResponse": SESsmtpResponse1,
                "SESreportingMTA": SESreportingMTA1,
                "SESDestinationAddress": SESDestinationAddress,
                "SESSourceAddress" : SESSourceAddress,
                "SESSourceIP" : SESSourceIP,
                "SESSubject": SESSubject,
                "SESMessageType": SESMessageType
            })
    elif (SESMessageType == "Complaint"):
        SESComplaintFeedbackType = SESMessage['complaint']['complaintFeedbackType']
        SESFeedbackId = SESMessage['complaint']['feedbackId']
        response = table.put_item(
            Item = {
                "SESMessageId": SESMessageId,
                "SnsPublishTime": SnsPublishTime,
                "SESComplaintFeedbackType": SESComplaintFeedbackType,
                "SESFeedbackId": SESFeedbackId,
                "SESDestinationAddress": SESDestinationAddress,
                "SESSourceAddress" : SESSourceAddress,
                "SESSourceIP" : SESSourceIP,
                "SESSubject": SESSubject,
                "SESMessageType": SESMessageType
            })
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
    }