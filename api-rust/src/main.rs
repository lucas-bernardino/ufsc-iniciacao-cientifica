use std::sync::Arc;

use axum::{routing::get, routing::post, Router};
use dotenv::dotenv;
use sqlx::{postgres::PgPoolOptions, Pool, Postgres};
use tower_http::cors::{Any, CorsLayer};

pub struct AppState {
    db: Pool<Postgres>,
}

mod handler;
mod models;

use crate::handler::{
    create_microphone_handler, get_filter_microphone_handler, get_microphone_handler, handle_csv,
    handle_download, get_Video, delete_data
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

    let app_state = Arc::new(AppState { db: pool.clone() });

    // let cors = CorsLayer::new().allow_methods(Any).allow_origin(Any);

    let app = Router::new()
        .route("/", get(|| async { "Hello, Rust!" }))
        .route("/create", post(create_microphone_handler))
        .route("/get", get(get_microphone_handler))
        .route("/filter", get(get_filter_microphone_handler))
        .route("/csv", get(handle_csv))
        .route("/video", post(handle_download))
        .route("/video", get(get_video))
        .route("/delete", get(delete_data))
        .with_state(app_state);

    println!("Running on http://localhost:3000");

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await.unwrap();
    axum::serve(listener, app).await.unwrap();

    // axum::Server::bind(&"0.0.0.0:3000".parse().unwrap())
    //     .serve(app.into_make_service())
    //     .await
    //     .unwrap();
}
