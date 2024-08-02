use rust_socketio::{
    asynchronous::{Client, ClientBuilder},
    Payload,
};
use serde::{Deserialize, Serialize};

use futures_util::FutureExt;

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
            let mut data = String::from("");
            match payload {
                Payload::Text(text) => data = text.first().unwrap().to_string(),
                _ => {}
            }
            let data = data.trim_matches('"');
            let parsed_data = data.split(",").collect::<Vec<&str>>();
            let min = parsed_data
                .get(0)
                .unwrap()
                .replace("min:", "")
                .parse::<u16>()
                .unwrap();
            let max = parsed_data
                .get(1)
                .unwrap()
                .replace("max:", "")
                .parse::<u16>()
                .unwrap();
            println!("Sucessfully got: {} and {}", min, max);
        }
        .boxed()
    };
    ClientBuilder::new("http://127.0.0.1:3000")
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
