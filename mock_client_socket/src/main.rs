use std::i32;

use rust_socketio::{
    asynchronous::{Client, ClientBuilder},
    Payload,
};
use serde::{Deserialize, Serialize};

use futures_util::{FutureExt, SinkExt, StreamExt};
use tokio_tungstenite::{self, tungstenite::Message};

#[derive(Debug, Deserialize, Serialize)]
struct MockBody {
    decibels: u16,
}

#[derive(Deserialize)]
struct UpdateResponse {
    min: u16,
    max: u16,
}

//const MIN_DECIBEL: u16 = 700;
//const MIN_DECIBEL_STOP: u16 = 580;

#[tokio::main(flavor = "current_thread")]
#[allow(unreachable_code)]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let client = reqwest::Client::new();
    let callback = |payload: Payload, socket: Client| {
        async move {
            let mut data = String::from("");
            match payload {
                Payload::Text(text) => data = text.first().unwrap().to_string(),
                _ => {}
            }
            let parsed_data: UpdateResponse = serde_json::from_str(data.as_str()).unwrap();
            let min = parsed_data.min;
            let max = parsed_data.max;
            println!("Sucessfully got: {min} and {max}");
        }
        .boxed()
    };
    let socket = ClientBuilder::new("http://127.0.0.1:3000")
        .namespace("")
        .on("update", callback)
        .connect()
        .await
        .expect("Connection failed");

    std::thread::sleep(std::time::Duration::from_secs(3));
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
