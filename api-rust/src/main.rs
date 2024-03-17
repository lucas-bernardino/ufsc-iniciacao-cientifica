use std::sync::Arc;

use axum::{routing::get, routing::post, Router};
use dotenv::dotenv;
use sqlx::{postgres::PgPoolOptions, Pool, Postgres};

pub struct AppState {
    db: Pool<Postgres>,
}

mod handler;
mod models;

use crate::handler::{create_microphone_handler, get_microphone_handler};

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

    let app = Router::new()
        .route("/", get(|| async { "Hello, Rust!" }))
        .route("/create", post(create_microphone_handler))
        .route("/get", get(get_microphone_handler))
        .with_state(app_state);

    println!("Running on http://localhost:3000");

    axum::Server::bind(&"0.0.0.0:3000".parse().unwrap())
        .serve(app.into_make_service())
        .await
        .unwrap();
}
