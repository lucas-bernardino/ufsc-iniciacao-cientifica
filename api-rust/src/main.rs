use std::{sync::Arc, u16};

use socketioxide::{
    extract::{Data, SocketRef},
    SocketIo,
};
use tokio::sync::Mutex;

use axum::{
    routing::{get, post},
    Router,
};
use dotenv::dotenv;
use sqlx::{postgres::PgPoolOptions, Pool, Postgres};
use std::net::SocketAddr;

#[derive(Clone)]
pub struct AppState {
    db: Pool<Postgres>,
    file_count: Arc<Mutex<u16>>,
}

mod handler;
mod models;

use crate::handler::{
    create_microphone_handler, delete_data, download_by_id, get_filter_microphone_handler,
    get_microphone_handler, get_video, handle_download, last_data, list_videos,
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

    let (layer, io) = SocketIo::new_layer();

    io.ns("/", socket_handler);

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
        .layer(layer)
        .with_state(app_state);

    println!("Server running sucessfully on port 3000 ✅");

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await.unwrap();
    axum::serve(
        listener,
        app.into_make_service_with_connect_info::<SocketAddr>(),
    )
    .await
    .unwrap();
}

async fn socket_handler(socket: SocketRef) {
    println!("Socket.IO connected: {:?} {:?}", socket.ns(), socket.id);

    socket.on("update", |socket: SocketRef, Data::<String>(data)| {
        let data = data.trim_matches('"');
        println!("Received: {data}\n");
        let parsed_data = data.split(",").collect::<Vec<&str>>();
        let min = parsed_data.get(0);
        let max = parsed_data.get(1);
        if min.is_none() || max.is_none() {
            emit_invalid_format_error(&socket);
            return;
        }
        let min = min.unwrap().replace("min:", "").parse::<u16>();
        let max = max.unwrap().replace("max:", "").parse::<u16>();
        if min.is_err() || max.is_err() {
            emit_invalid_format_error(&socket);
            return;
        }

        let _ = socket.broadcast().emit("update", data).ok();
    });
}

fn emit_invalid_format_error(socket: &SocketRef) {
    socket
        .emit(
            "update",
            "Invalid data format. Should be 'min:<value>,max:<value>'",
        )
        .unwrap();
}
