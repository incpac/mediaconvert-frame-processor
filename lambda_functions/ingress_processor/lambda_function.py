import boto3
import json
import os
from string import Template


dynamodb = boto3.resource('dynamodb')
mediaconvert = boto3.client('mediaconvert')

mediaconvert_endpoints = mediaconvert.describe_endpoints()
mediaconvert = boto3.client('mediaconvert', endpoint_url=mediaconvert_endpoints['Endpoints'][0]['Url'])

table = dynamodb.Table(os.environ.get('JOBS_TABLE'))

frames_bucket = os.environ.get('FRAMES_BUCKET')
mediaconvert_role = os.environ.get('MEDIACONVERT_ROLE')


def lambda_handler(event, context):
    for record in event['Records']:
        filepath = record['s3']['object']['key']
        video_id = '/'.join(filepath.split('/')[:-1])
        input_bucket = record['s3']['bucket']['name']

        input_path = f's3://{input_bucket}/{filepath}'
        output_path = f's3://{frames_bucket}/{video_id}/'        

        job_config = {
            'input_path': input_path,
            'output_path': output_path
        }
        
        with open('./mediaconvert_job.json.tpl', 'r') as f:
            src = Template(f.read()).substitute(job_config)
            job = json.loads(src)
        
        res = mediaconvert.create_job(
            Role=mediaconvert_role, 
            Settings=job,
            UserMetadata={
                'videoId': video_id,
                'task': 'GENERATE_FRAMES'
            }
        )
        mediaconvert_job_id = res['Job']['Id']

        table.update_item(
                Key={'VideoId': video_id},
                UpdateExpression='SET ' +
                'IngressVideoBucket= :ingress_video_bucket,' +
                'IngressVideoKey= :ingress_video_key,' +
                'MediaConvertJobId= :mediaconvert_job_id',
                ExpressionAttributeValues={
                    ':ingress_video_bucket': record['s3']['bucket']['name'],
                    ':ingress_video_key': filepath,
                    ':mediaconvert_job_id': mediaconvert_job_id
                }
        )
