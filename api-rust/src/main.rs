use std::{process::Stdio, sync::Arc};

use serde::Deserialize;
use tokio::sync::Mutex;

use axum::{routing::get, routing::post, Router};
use dotenv::dotenv;
use sqlx::{postgres::PgPoolOptions, Pool, Postgres};

use tokio::io::{AsyncBufReadExt, BufReader};

use lettre::message::header::ContentType;
use lettre::transport::smtp::authentication::Credentials;
use lettre::{Message, SmtpTransport, Transport};

#[derive(Clone)]
pub struct AppState {
    db: Pool<Postgres>,
    file_count: Arc<Mutex<u16>>,
}

#[derive(Deserialize)]
struct RouteResponse {
    url: String,
}

mod handler;
mod models;

use crate::handler::{
    create_microphone_handler, delete_data, download_by_id, get_filter_microphone_handler,
    get_microphone_handler, get_video, handle_download, handle_localhost_route, last_data,
    list_videos,
};

#[tokio::main]
async fn main() {
    dotenv().ok();

    let mut localhostrun_url = init_server_email().await.unwrap();

    println!("Started with the url: {localhostrun_url}");

    let database_url = std::env::var("DATABASE_URL").expect("Missing DATABASE_URL in .env");
    let pool = match PgPoolOptions::new()
        .max_connections(10)
        .connect(&database_url)
        .await
    {
        Ok(pool) => {
            println!("✅ Connection to the database is successful!");
            pool
        }
        Err(err) => {
            println!("🔥 Failed to connect to the database: {:?}", err);
            std::process::exit(1);
        }
    };

    let app_state = Arc::new(AppState {
        db: pool.clone(),
        file_count: Arc::new(Mutex::new(0)),
    });

    let app = Router::new()
        .route("/", get(|| async { "Running" }))
        .route("/create", post(create_microphone_handler))
        .route("/get", get(get_microphone_handler))
        .route("/filter", get(get_filter_microphone_handler))
        .route("/video", post(handle_download))
        .route("/download", get(get_video))
        .route("/delete", get(delete_data))
        .route("/list", get(list_videos))
        .route("/download/video/:id", get(download_by_id))
        .route("/last", get(last_data))
        .route("/route/init", get(handle_localhost_route))
        .with_state(app_state);

    let script_check = tokio::spawn(async move {
        loop {
            let response = reqwest::Client::new()
                .get(localhostrun_url.clone())
                .header("Cache-Control", "no-cache, no-store, must-revalidate")
                .header("Pragma", "no-cache")
                .header("Expires", "0")
                .send()
                .await
                .unwrap()
                .status();
            if response != 200 {
                let init_response = reqwest::Client::new()
                    .get("http://localhost:3000/route/init")
                    .send()
                    .await
                    .unwrap()
                    .json::<RouteResponse>()
                    .await
                    .unwrap();
                let new_url = init_response.url;
                send_email(&new_url).await.unwrap();
                println!("Changed url to: {new_url}");
                localhostrun_url = new_url;
            }
            tokio::time::sleep(std::time::Duration::from_secs(1)).await;
        }
    });

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await.unwrap();
    axum::serve(listener, app).await.unwrap();

    //println!("Server running sucessfully on port 3000 ✅");

    script_check.await.unwrap();
}

async fn start_server() -> Result<String, Box<dyn std::error::Error + 'static>> {
    let init_command = tokio::process::Command::new("ssh")
        .args(["-R", "80:localhost:3000", "ssh.localhost.run"])
        .stdout(Stdio::piped())
        .spawn();

    let stdout = init_command?.stdout.take();

    let mut reader = match stdout {
        Some(s) => BufReader::new(s).lines(),
        None => return Err("Could not get stdout".into()),
    };

    let mut url = String::new();

    while let Some(line) = reader.next_line().await.unwrap() {
        if line.contains("https") {
            let remove_trash = line.trim().replace(" ", "");
            let vec_url = remove_trash.split(",").collect::<Vec<_>>();
            url = vec_url.get(1).unwrap().to_string();
            break;
        }
    }

    Ok(url)
}

async fn send_email(url: &String) -> Result<(), Box<dyn std::error::Error + 'static>> {
    let email = Message::builder()
        .from("microfoneprojeto@gmail.com".parse()?)
        .to("microfoneprojeto@gmail.com".parse()?)
        .subject("API")
        .header(ContentType::TEXT_PLAIN)
        .body(url.clone())?;

    let password = std::env::var("GMAIL_PASSWORD")
        .expect("Missing GMAIL_PASSWORD in .env file!")
        .replace("_", " ");

    let creds = Credentials::new("microfoneprojeto@gmail.com".to_owned(), password.to_owned());

    let mailer = SmtpTransport::relay("smtp.gmail.com")
        .unwrap()
        .credentials(creds)
        .build();

    match mailer.send(&email) {
        Ok(_) => println!("Email sent successfully!"),
        Err(e) => panic!("Could not send email: {e:?}"),
    }

    Ok(())
}

async fn init_server_email() -> Result<String, Box<dyn std::error::Error + 'static>> {
    let url = match start_server().await {
        Ok(u) => u,
        Err(e) => {
            return Err(format!(
                "Could not send email due to an error in starting the server\nError: {}",
                e.to_string()
            )
            .into())
        }
    };

    send_email(&url).await.unwrap();
    Ok(url)
}
