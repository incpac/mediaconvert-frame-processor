import boto3
import os

dynamodb = boto3.resource('dynamodb')
s3 = boto3.client('s3')

table = dynamodb.Table(os.environ.get('JOBS_TABLE'))
raw_frames_bucket = os.environ.get('RAW_FRAMES_BUCKET')

def get_s3_key_count(bucket_name, path, continue_token=None):
    if continue_token != None:
        s3_res = s3.list_objects_v2(
                Bucket=bucket_name,
                Prefix=path,
                ContinuationToken=continue_token)
    else:
        s3_res = s3.list_objects_v2(
                Bucket=bucket_name,
                Prefix=path)

    count = s3_res['KeyCount']

    if s3_res['IsTruncated']:
        count += get_s3_key_count(bucket_name, path, s3_res['NextContinuationToken'])

    return count


def video_split_handler(event):
    video_id = event['detail']['userMetadata']['videoId']
    mediaconvert_status = event['detail']['status']

    total_frames = get_s3_key_count(raw_frames_bucket, video_id) - 1 # subtracting the video file 

    table.update_item(
            Key={'VideoId': video_id},
            UpdateExpression='SET MediaConvertStatus= :mediaconvertStatus, TotalFrames= :totalFrames',
            ExpressionAttributeValues={':mediaconvertStatus': mediaconvert_status, ':totalFrames': total_frames}
    )


def lambda_handler(event, context):
    if event.get('detail', {}).get('userMetadata', {}).get('task') == 'GENERATE_FRAMES':
            return video_split_handler(event)
