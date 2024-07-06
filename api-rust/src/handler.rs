use axum::body::Body;
use axum::extract::{Path, Query, Request};
use axum::http::header;
use axum::response::Response;
use axum::{extract::State, http::StatusCode, response::IntoResponse, Json};
use csv::WriterBuilder;
use lettre::message::header::ContentType;
use lettre::transport::smtp::authentication::Credentials;
use lettre::{Message, SmtpTransport, Transport};
use std::process::{Command, Stdio};
use std::sync::Arc;
use tokio::io::{AsyncBufReadExt, BufReader};
use tokio_stream::StreamExt;

use tokio_util::io::{ReaderStream, StreamReader};

use crate::models::{CreateMicrophoneSchema, Filter, MicrophoneModel, VideoInfo};
use crate::AppState;

use axum::debug_handler;

pub async fn get_microphone_handler(
    State(data): State<Arc<AppState>>,
) -> Result<impl IntoResponse, (StatusCode, Json<serde_json::Value>)> {
    let query = sqlx::query_as!(MicrophoneModel, "SELECT * FROM microphone")
        .fetch_all(&data.db)
        .await;

    if query.is_err() {
        let error_response = serde_json::json!({
            "status": "INTERNAL_SERVER_ERROR",
            "message": "Something went wrong in the server."
        });
        return Err((StatusCode::INTERNAL_SERVER_ERROR, Json(error_response)));
    }

    let query_result = query.unwrap();

    Ok(Json(query_result))
}

pub async fn create_microphone_handler(
    State(data): State<Arc<AppState>>,
    Json(payload): Json<CreateMicrophoneSchema>,
) -> impl IntoResponse {
    let query = sqlx::query_as!(
        CreateMicrophoneSchema,
        "INSERT INTO microphone ( decibels ) VALUES ( $1 )",
        payload.decibels
    )
    .fetch_one(&data.db)
    .await;

    match query {
        Ok(_) => StatusCode::CREATED,
        Err(_) => StatusCode::INTERNAL_SERVER_ERROR,
    };
}

fn handle_serialization(
    filename: &'static str,
    data: Vec<MicrophoneModel>,
) -> Result<(), csv::Error> {
    let mut csv_wtr = WriterBuilder::new().from_path(filename).unwrap();

    for value in data.iter() {
        csv_wtr.serialize(value)?;
    }

    Ok(())
}

pub async fn get_filter_microphone_handler(
    State(data): State<Arc<AppState>>,
    Query(filter): Query<Filter>,
) -> Response {
    let Filter {
        min,
        limit,
        ordered,
    } = filter;

    let min = min.unwrap_or(0.0);
    let limit = limit.unwrap_or(std::i64::MAX);

    let query = match ordered.as_deref() {
        Some("decibels") => {
            sqlx::query_as!(
                MicrophoneModel,
                "SELECT * FROM microphone WHERE decibels > $1 ORDER BY decibels DESC LIMIT $2",
                min,
                limit
            )
            .fetch_all(&data.db)
            .await
        }
        Some("created_at") => {
            sqlx::query_as!(
                MicrophoneModel,
                "SELECT * FROM microphone WHERE decibels > $1 ORDER BY created_at DESC LIMIT $2",
                min,
                limit
            )
            .fetch_all(&data.db)
            .await
        }
        None => {
            sqlx::query_as!(
                MicrophoneModel,
                "SELECT * FROM microphone WHERE decibels > $1 ORDER BY id DESC LIMIT $2",
                min,
                limit
            )
            .fetch_all(&data.db)
            .await
        }
        Some(_) => {
            return (StatusCode::UNPROCESSABLE_ENTITY, Json(serde_json::json!({"error": "query `ordered` must have either `decibels` or `created_at` as a value"}))).into_response();
        }
    };

    if query.is_err() {
        let err_msg = query.unwrap_err().to_string();
        return (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(serde_json::json!({ "error": err_msg })),
        )
            .into_response();
    }

    match handle_serialization("data.csv", query.unwrap()) {
        Ok(_) => {}
        Err(err) => {
            let error_response = serde_json::json!({
                "status": "INTERNAL_SERVER_ERROR",
                "message": format!("Something went wrong with CSV serialization: {err}")
            });
            return (StatusCode::INTERNAL_SERVER_ERROR, Json(error_response)).into_response();
        }
    }

    let file = tokio::fs::File::open("data.csv").await.unwrap();

    let stream = ReaderStream::new(file);

    let body = Body::from_stream(stream);

    let headers = [
        (header::CONTENT_TYPE, "text/csv"),
        (header::CONTENT_DISPOSITION, "attachment; filename=data.csv"),
    ];

    (headers, body).into_response()
}

pub async fn handle_download(State(data): State<Arc<AppState>>, req: Request) -> Response {
    let mut file_count = data.file_count.lock().await;

    let mut file = tokio::fs::File::create(format!("video{}.mkv", file_count))
        .await
        .unwrap();

    let stream = req.into_body().into_data_stream();

    let stream = stream
        .map(|result| result.map_err(|err| std::io::Error::new(std::io::ErrorKind::Other, err)));

    let mut body_stream = StreamReader::new(stream);

    tokio::io::copy(&mut body_stream, &mut file).await.unwrap();

    *file_count += 1;

    "".into_response()
}

#[debug_handler]
pub async fn get_video(State(data): State<Arc<AppState>>) -> Response {
    let mut file_count = data.file_count.lock().await;

    println!("File count: {file_count}");

    let file = tokio::fs::File::open(format!("video{}.mkv", file_count))
        .await
        .unwrap();

    let stream = ReaderStream::new(file);

    let body = Body::from_stream(stream);

    let headers = [
        (header::CONTENT_TYPE, "video/webm"),
        (
            header::CONTENT_DISPOSITION,
            "attachment; filename=video.mkv",
        ),
    ];

    *file_count += 1;

    (headers, body).into_response()
}

pub async fn delete_data(State(data): State<Arc<AppState>>) -> Response {
    let query = sqlx::query!("TRUNCATE microphone")
        .fetch_one(&data.db)
        .await;

    match query {
        Ok(_) => "Successfully deleted all data".into_response(),
        Err(err) => format!("Error found: {}", err).into_response(),
    }
}

pub async fn list_videos() -> Response {
    let ls = Command::new("ls")
        .arg("-lh")
        .stdout(Stdio::piped())
        .spawn()
        .unwrap();

    let grep = Command::new("grep")
        .arg("mkv")
        .stdin(Stdio::from(ls.stdout.unwrap()))
        .stdout(Stdio::piped())
        .spawn()
        .unwrap()
        .wait_with_output()
        .unwrap();

    let video_names_string = String::from_utf8(grep.stdout).unwrap();

    let mut foo_vec: Vec<VideoInfo> = Vec::new();

    video_names_string
        .lines()
        .map(|line| line.split_whitespace().last().unwrap())
        .for_each(|name| {
            println!("Printing name: {:#?}", name);
            let ffprobe = Command::new("ffprobe")
                .args([
                    "-i",
                    name,
                    "-show_entries",
                    "format=duration",
                    "-v",
                    "quiet",
                ])
                .stdout(Stdio::piped())
                .spawn()
                .unwrap()
                .wait_with_output()
                .unwrap();

            let du = Command::new("du")
                .args(["-h", name])
                .stdout(Stdio::piped())
                .spawn()
                .unwrap()
                .wait_with_output()
                .unwrap();

            let _ = String::from_utf8(ffprobe.stdout).unwrap();

            let du_output = String::from_utf8(du.stdout).unwrap();
            let size = du_output.split_whitespace().next().unwrap();

            foo_vec.push(VideoInfo {
                name: name.to_string(),
                duration: "-".to_string(),
                size: size.to_string(),
            });
        });

    Json(serde_json::json!(foo_vec)).into_response()
}

pub async fn download_by_id(Path(id): Path<u16>) -> Response {
    let file = tokio::fs::File::open(format!("video{id}.mkv")).await;

    if file.is_err() {
        let body = serde_json::json!({
            "status": "BAD_REQUEST",
            "message": "File does not exist"});
        return (StatusCode::BAD_REQUEST, Json(body)).into_response();
    }

    let stream = ReaderStream::new(file.unwrap());

    let body = Body::from_stream(stream);

    let headers = [
        (header::CONTENT_TYPE, "video/webm"),
        (
            header::CONTENT_DISPOSITION,
            "attachment; filename=video.mkv",
        ),
    ];

    (headers, body).into_response()
}

pub async fn last_data(
    State(data): State<Arc<AppState>>,
) -> Result<impl IntoResponse, (StatusCode, Json<serde_json::Value>)> {
    let query = sqlx::query_as!(
        MicrophoneModel,
        "SELECT * FROM microphone ORDER BY created_at DESC LIMIT 1",
    )
    .fetch_one(&data.db)
    .await;

    if query.is_err() {
        let error_response = serde_json::json!({
            "status": "INTERNAL_SERVER_ERROR",
            "message": "Something went wrong in the server."
        });
        return Err((StatusCode::INTERNAL_SERVER_ERROR, Json(error_response)));
    }

    let query_result = query.unwrap();

    Ok(Json(query_result))
}

async fn send_email(url: &str) -> Result<(), Box<dyn std::error::Error + 'static>> {
    let email = Message::builder()
        .from("microfoneprojeto@gmail.com".parse()?)
        .to("microfoneprojeto@gmail.com".parse()?)
        .subject("API")
        .header(ContentType::TEXT_PLAIN)
        .body(url.to_string())?;

    let password = std::env::var("GMAIL_PASSWORD")?.replace("_", " ");

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

pub async fn handle_localhost_route() -> impl IntoResponse {
    let init_command = tokio::process::Command::new("ssh")
        .args(["-R", "80:localhost:3000", "ssh.localhost.run"])
        .stdout(Stdio::piped())
        .spawn();

    let stdout = init_command.unwrap().stdout.take().unwrap();

    let mut reader = BufReader::new(stdout).lines();

    let mut url = String::new();

    while let Some(line) = reader.next_line().await.unwrap() {
        if line.contains("https") {
            let remove_trash = line.trim().replace(" ", "");
            let vec_url = remove_trash.split(",").collect::<Vec<_>>();
            url = vec_url.get(1).unwrap().to_string();
            break;
        }
    }

    match send_email(url.as_str()).await {
        Ok(()) => println!("Send email successfully in handle_localhost_route"),
        Err(e) => println!(
            "Error when sending the email in handle_localhost_route: {}",
            e.to_string()
        ),
    };

    Json(serde_json::json!({ "url": url }))
}
