use serde::{Deserialize, Serialize};

use futures_util::{SinkExt, StreamExt};
use tokio_tungstenite::{self, tungstenite::Message};
#[derive(Debug, Deserialize, Serialize)]
struct MockBody {
    decibels: u16,
}

//const MIN_DECIBEL: u16 = 700;
//const MIN_DECIBEL_STOP: u16 = 580;

#[tokio::main(flavor = "current_thread")]
#[allow(unreachable_code)]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let client = reqwest::Client::new();
    let (mut ws_stream, _) =
        tokio_tungstenite::connect_async("ws://127.0.0.1:3000/ws/microphone").await?;
    tokio::spawn(async move {
        loop {
            if let Some(msg) = ws_stream.next().await {
                println!("Received message: {}", msg.unwrap().to_text().unwrap());
            }
        }
    });
    loop {
        for i in 1..100 {
            let mock_body = MockBody { decibels: i * 10 };
            client
                .post("http://localhost:3000/create")
                .json(&mock_body)
                .send()
                .await?;
            std::thread::sleep(std::time::Duration::from_secs(1));
            println!(
                "Sending request to server with the following body: {}",
                mock_body.decibels
            );
        }
    }

    Ok(())
}
