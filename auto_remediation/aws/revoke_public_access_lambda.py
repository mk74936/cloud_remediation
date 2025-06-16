import json
import boto3

s3 = boto3.client('s3')

def lambda_handler(event, context):
    print("Received event:", json.dumps(event))

    invoking_event = json.loads(event['invokingEvent'])
    resource_id = invoking_event['configurationItem']['resourceId']
    bucket_name = invoking_event['configurationItem']['resourceName']

    print(f"Remediating S3 Bucket: {bucket_name}")

    try:
        # Set the bucket's ACL to private
        s3.put_bucket_acl(Bucket=bucket_name, ACL='private')

        evaluation = {
            'ComplianceType': 'COMPLIANT',
            'Annotation': 'Automatically remediated: Public access removed.',
            'OrderingTimestamp': invoking_event['configurationItem']['configurationItemCaptureTime']
        }

        # Optional: Report back to AWS Config
        config = boto3.client('config')
        config.put_evaluations(
            Evaluations=[
                {
                    'ComplianceResourceType': 'AWS::S3::Bucket',
                    'ComplianceResourceId': resource_id,
                    'ComplianceType': 'COMPLIANT',
                    'Annotation': evaluation['Annotation'],
                    'OrderingTimestamp': evaluation['OrderingTimestamp']
                },
            ],
            ResultToken=event['resultToken']
        )

        return {
            'statusCode': 200,
            'body': f"Bucket {bucket_name} ACL set to private."
        }

    except Exception as e:
        print(f"Error remediating bucket {bucket_name}: {str(e)}")
        raise e
