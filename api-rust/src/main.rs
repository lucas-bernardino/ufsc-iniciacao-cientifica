use std::{process::Stdio, sync::Arc};

use tokio::sync::Mutex;

use axum::{routing::get, routing::post, Router};
use dotenv::dotenv;
use sqlx::{postgres::PgPoolOptions, Pool, Postgres};
use tower_http::cors::{Any, CorsLayer};

use tokio::io::{self, AsyncBufReadExt, BufReader};

#[derive(Clone)]
pub struct AppState {
    db: Pool<Postgres>,
    file_count: Arc<Mutex<u16>>,
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

    let url = start_server();

    println!("Start running with public url: {}", url.await.unwrap());

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
        .route("/", get(|| async { "Hello, Rust!" }))
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

    println!("Running on http://localhost:3000");

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await.unwrap();
    axum::serve(listener, app).await.unwrap();
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
