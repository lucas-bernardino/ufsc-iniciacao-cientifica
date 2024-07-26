use reqwest::{
    header::{CONTENT_DISPOSITION, CONTENT_TYPE},
    Body, Client,
};
use serde::{Deserialize, Serialize};
use tokio_util::io::ReaderStream;

use std::{thread, time};

#[derive(Debug, Deserialize, Serialize)]
struct MockBody {
    decibels: u16,
}

const sleep_time: time::Duration = time::Duration::from_secs(1);

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let client = reqwest::Client::new();

    println!("Current time: {:#?}", time::Instant::now());

    for i in 1..100 {
        let mock_body = MockBody { decibels: i * 10 };
        let res = client
            .post("http://localhost:3000/create")
            .json(&mock_body)
            .send()
            .await?;
        thread::sleep(sleep_time);
        println!(
            "Sending request to server with the following body: {}",
            mock_body.decibels
        );
    }

    Ok(())
}

async fn mock_video(client: &Client) {
    let file = tokio::fs::File::open("song.mkv").await.unwrap();
    let stream = ReaderStream::new(file);

    let body_stream = Body::wrap_stream(stream);

    let response = client
        .post("http://127.0.0.1:3000/video")
        .header(CONTENT_TYPE, "video/webm")
        .header(CONTENT_DISPOSITION, "attachment; filename=song.mkv")
        .body(body_stream)
        .send();

    println!("Response: {x:#?}", x = response.await);
}
