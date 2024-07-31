use std::sync::Arc;

use axum::extract::State;
use tokio::sync::Mutex;

use axum::{
    extract::{
        ws::{self, Message, WebSocket},
        WebSocketUpgrade,
    },
    response::Response,
    routing::{get, post},
    Router,
};
use dotenv::dotenv;
use sqlx::{postgres::PgPoolOptions, Pool, Postgres};
use std::net::SocketAddr;

#[derive(Default, Debug)]
struct SocketCommunication {
    microphone_message: String,
    flutter_message: String,
    new_message: bool,
}

impl SocketCommunication {
    fn update_mic_msg(&mut self, new_mic_message: String) {
        self.microphone_message = new_mic_message;
    }

    fn update_flutter_msg(&mut self, new_flutter_message: String) {
        self.flutter_message = new_flutter_message;
    }
}

#[derive(Clone)]
pub struct AppState {
    db: Pool<Postgres>,
    file_count: Arc<Mutex<u16>>,
    socket_communication: Arc<Mutex<SocketCommunication>>,
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
        socket_communication: Arc::new(Mutex::new(SocketCommunication::default())),
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
        .route("/ws/microphone", get(socket_mic))
        .route("/ws/flutter", get(socket_flu))
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

async fn socket_mic(ws: WebSocketUpgrade, State(state): State<Arc<AppState>>) -> Response {
    ws.on_upgrade(move |socket| socket_mic_handler(socket, state))
}

async fn socket_mic_handler(mut socket: WebSocket, state: Arc<AppState>) {
    while let Some(msg) = socket.recv().await {
        let msg = if let Ok(msg) = msg {
            msg
        } else {
            // client disconnected
            return;
        };

        if msg.to_text().unwrap() == "microphone_init" {
            let mut sock_comm = state.socket_communication.lock().await;
            sock_comm.update_mic_msg(msg.to_text().unwrap().to_string());
            sock_comm.new_message = true;
        }

        println!("Data - {}", msg.to_text().unwrap());

        if socket.send(msg.clone()).await.is_err() {
            // client disconnected
            return;
        }
    }
}

async fn socket_flu(ws: WebSocketUpgrade, State(state): State<Arc<AppState>>) -> Response {
    ws.on_upgrade(move |socket| socket_flu_handler(socket, state))
}

async fn socket_flu_handler(mut socket: WebSocket, state: Arc<AppState>) {
    while let Some(msg) = socket.recv().await {
        let msg = if let Ok(msg) = msg {
            msg
        } else {
            // client disconnected
            return;
        };

        let mut sock_comm = state.socket_communication.lock().await;

        if msg.to_text().unwrap() == "flutter_init" {
            sock_comm.update_flutter_msg(msg.to_text().unwrap().to_string());
        }

        if sock_comm.new_message {
            socket
                .send(Message::Text("O CARA JA DEU O FLUTTER_INIT".to_string()))
                .await
                .unwrap();
        }

        println!("Data - {}", msg.to_text().unwrap());

        if socket.send(msg.clone()).await.is_err() {
            // client disconnected
            return;
        }
    }
}
