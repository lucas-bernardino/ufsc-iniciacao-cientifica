use reqwest::{
    header::{CONTENT_DISPOSITION, CONTENT_TYPE},
    Body,
};
use tokio_util::io::ReaderStream;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let client = reqwest::Client::new();

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

    Ok(())
}
