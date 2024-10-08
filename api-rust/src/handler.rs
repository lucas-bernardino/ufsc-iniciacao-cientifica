use axum::body::Body;
use axum::extract::{Path, Query, Request};
use axum::http::header;
use axum::response::Response;
use axum::{extract::State, http::StatusCode, response::IntoResponse, Json};
use csv::WriterBuilder;
use std::process::{Command, Stdio};
use std::sync::Arc;
use tokio_stream::StreamExt;

use tokio_util::io::{ReaderStream, StreamReader};

use crate::models::{CreateMicrophoneSchema, Filter, MicrophoneModel, VideoInfo};
use crate::AppState;


use rand::distributions::{Alphanumeric, DistString};

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
    mut data: Vec<MicrophoneModel>,
) -> Result<(), csv::Error> {
    let mut csv_wtr = WriterBuilder::new().from_path(filename).unwrap();

    for value in data.iter_mut() {
        value.decibels = value.decibels / 10.0;
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
                "SELECT * FROM microphone WHERE decibels > $1 ORDER BY decibels LIMIT $2",
                min,
                limit
            )
            .fetch_all(&data.db)
            .await
        }
        Some("created_at") => {
            sqlx::query_as!(
                MicrophoneModel,
                "SELECT * FROM microphone WHERE decibels > $1 ORDER BY created_at LIMIT $2",
                min,
                limit
            )
            .fetch_all(&data.db)
            .await
        }
        None => {
            sqlx::query_as!(
                MicrophoneModel,
                "SELECT * FROM microphone WHERE decibels > $1 ORDER BY id LIMIT $2",
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

pub async fn handle_download(req: Request) -> Response {
    let rand_id = Alphanumeric.sample_string(&mut rand::thread_rng(), 10);

    let mut file = tokio::fs::File::create(format!("video-{}.mkv", rand_id))
        .await
        .unwrap();

    let stream = req.into_body().into_data_stream();

    let stream = stream
        .map(|result| result.map_err(|err| std::io::Error::new(std::io::ErrorKind::Other, err)));

    let mut body_stream = StreamReader::new(stream);

    tokio::io::copy(&mut body_stream, &mut file).await.unwrap();

    "".into_response()
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
        .map(|line| line.split_whitespace().collect::<Vec<_>>())
        .for_each(|info| {
            let video_name = info.get(8).unwrap().to_string();
            let video_hour = info.get(7).unwrap().to_string();
            let video_day = info.get(6).unwrap().to_string();
            let video_month = info.get(5).unwrap().to_string();
            let video_size = info.get(4).unwrap().to_string();

            foo_vec.push(VideoInfo {
                video_name,
                video_hour,
                video_day,
                video_month,
                video_size,
            });
        });

    Json(serde_json::json!(foo_vec)).into_response()
}

pub async fn download_by_name(Path(name): Path<String>) -> Response {
    let file = tokio::fs::File::open(format!("./{name}")).await;

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

pub async fn delete_video(Path(name): Path<String>) -> impl IntoResponse {
    if !name.contains("mkv") {
        return StatusCode::BAD_REQUEST;
    }
    match std::fs::remove_file(format!("./{}", name)) {
        Ok(_) => StatusCode::OK,
        Err(_) => StatusCode::INTERNAL_SERVER_ERROR,
    }
}
