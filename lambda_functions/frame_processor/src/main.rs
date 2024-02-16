extern crate aws_config;
extern crate aws_lambda_events;
extern crate aws_sdk_s3;
extern crate image;

use aws_config::{BehaviorVersion, load_defaults};
use aws_lambda_events::event::s3::S3Event;
use aws_sdk_s3::{Client, primitives::ByteStream};
use lambda_runtime::{run, service_fn, Error, LambdaEvent};
use std::{fs::File, io::Write, path::Path, env::var, str::FromStr};
use tracing::Level;

mod sobel;


static TMP_SOURCE_FILE: &str = "/tmp/source.jpg";
static TMP_OUTPUT_FILE: &str = "/tmp/output.jpg";


async fn handle_record(client: Client, bucket: &str, key: &str) -> Result<(), Error> {
    tracing::debug!({%bucket, %key}, "Handling record");

    if !key.ends_with(".jpg") {
        tracing::info!({%key}, "File is not a JPEG image, exiting");
        return Ok(())
    }

    let output_bucket = var("OUTPUT_BUCKET").unwrap();
    let blur_modifier = var("BLUR_MODIFIER").unwrap().parse::<i32>().unwrap();

    let mut source_file = File::create(&TMP_SOURCE_FILE)?;
    let mut object = client
        .get_object()
        .bucket(bucket)
        .key(key)
        .send()
        .await?;

    while let Some(bytes) = object.body.try_next().await? {
        source_file.write_all(&bytes)?;
    }
    tracing::debug!({%key, %TMP_SOURCE_FILE}, "Downloaded file from S3 to local disk");

    sobel::process_image(TMP_SOURCE_FILE, TMP_OUTPUT_FILE, blur_modifier);
    tracing::debug!({%TMP_SOURCE_FILE, %TMP_OUTPUT_FILE, %blur_modifier}, "Finished processing image");

    let body = ByteStream::from_path(Path::new(TMP_OUTPUT_FILE)).await;
    let _ = client
        .put_object()
        .bucket(&output_bucket)
        .key(key)
        .body(body.unwrap())
        .send()
        .await;
    tracing::debug!({%TMP_OUTPUT_FILE, %output_bucket, %key}, "Uploaded output file to S3");

    Ok(())
}


#[tracing::instrument(skip(event), fields(req_id = %event.context.request_id))]
async fn function_handler(event: LambdaEvent<S3Event>) -> Result<(), Error> {
    let aws_config = load_defaults(BehaviorVersion::v2023_11_09()).await;
    let client = Client::new(&aws_config);

    for record in event.payload.records.iter() {
        let bucket = record.s3.bucket.name.clone().expect("Could not get bucket name from record");
        let key = record.s3.object.key.clone().expect("Could not get key from object record");

        tracing::debug!({%bucket, %key}, "Received new file");

        match handle_record(client.clone(), &bucket, &key).await {
            Ok(()) => {
                tracing::info!({%bucket, %key}, "Processed file");
            }
            Err(err) => {
                tracing::error!({%bucket, %key, %err}, "Failed to process file");
            }
        }
    }
    Ok(())
}

#[tokio::main]
async fn main() -> Result<(), Error> {
    tracing_subscriber::fmt().json()
        .with_max_level(Level::from_str(&std::env::var("LOG_LEVEL").unwrap()).unwrap())
        //.with_max_level(tracing::Level::INFO)
        .with_current_span(false)   // remove duplicate information from the logs
        //.with_ansi(false)           // disable ANSI colour codes which cause problems with CLoudWatchLogs
        .without_time()             // disabling time is handy because CloudWatch will add the ingestion time.
        .with_target(false)         // disable printing the name of the module in every log line.
        .init();
    run(service_fn(function_handler)).await
}
