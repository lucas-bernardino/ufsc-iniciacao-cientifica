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

//const MIN_DECIBEL: u16 = 700;
//const MIN_DECIBEL_STOP: u16 = 580;

#[tokio::main(flavor = "current_thread")]
#[allow(unreachable_code)]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let client = reqwest::Client::new();
    let callback = |payload: Payload, socket: Client| {
        async move {
            match payload {
                Payload::Text(str) => println!("Received: {:#?}", str),
                Payload::Binary(bin_data) => println!("Received bytes: {:#?}", bin_data),
                _ => println!("Outro"),
            }
            //socket
            //    .emit("message", "risos")
            //    .await
            //    .expect("Server unreachable")
        }
        .boxed()
    };
    let socket = ClientBuilder::new("http://127.0.0.1:3000")
        .namespace("")
        .on("message", callback)
        .connect()
        .await
        .expect("Connection failed");

    std::thread::sleep(std::time::Duration::from_secs(3));
    socket.emit("message", "mic").await.unwrap();
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
