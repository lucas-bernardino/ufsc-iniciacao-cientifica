use std::sync::Arc;

use tokio::sync::Mutex;

use axum::{routing::get, routing::post, Router};
use dotenv::dotenv;
use sqlx::{postgres::PgPoolOptions, Pool, Postgres};
use tower_http::cors::{Any, CorsLayer};

#[derive(Clone)]
pub struct AppState {
    db: Pool<Postgres>,
    file_count: Arc<Mutex<u16>>,
}

mod handler;
mod models;

use crate::handler::{
    create_microphone_handler, delete_data, download_by_id, get_filter_microphone_handler,
    get_microphone_handler, get_video, handle_download, list_videos, last_data
};

#[tokio::main]
async fn main() {
    dotenv().ok();

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
        .with_state(app_state);

    println!("Running on http://localhost:3000");

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
