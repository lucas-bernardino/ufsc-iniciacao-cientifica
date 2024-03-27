use std::fs;
use std::sync::Arc;

use axum::body::Body;
use axum::extract::Query;
use axum::http::header;
use axum::response::Response;
use axum::{extract::State, http::StatusCode, response::IntoResponse, Json};
use csv::{Writer, WriterBuilder};
use tower_http::services::ServeFile;

use tokio_util::io::ReaderStream;

use crate::models::{CreateMicrophoneSchema, Filter, MicrophoneModel};
use crate::AppState;

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

    match query {
        Ok(query_result) => (StatusCode::OK, Json(query_result)).into_response(),
        Err(_) => {
            let err_msg = query.unwrap_err().to_string();
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(serde_json::json!({ "error": err_msg })),
            )
                .into_response()
        }
    }
}

pub async fn handle_csv(State(data): State<Arc<AppState>>) -> Response {
    let query = sqlx::query_as!(MicrophoneModel, "SELECT * FROM microphone")
        .fetch_all(&data.db)
        .await;

    if query.is_err() {
        let error_response = serde_json::json!({
            "status": "INTERNAL_SERVER_ERROR",
            "message": "Something went wrong in the server."
        });
        return (StatusCode::INTERNAL_SERVER_ERROR, Json(error_response)).into_response();
    }

    let mut csv_wtr = WriterBuilder::new().from_path("data.csv").unwrap();

    csv_wtr.serialize(query.unwrap()).unwrap();

    let file = tokio::fs::File::open("data.csv").await.unwrap();

    let stream = ReaderStream::new(file);

    let body = Body::from_stream(stream);

    let headers = [
        (header::CONTENT_TYPE, "text/csv"),
        (header::CONTENT_DISPOSITION, "attachment; filename=data.csv"),
    ];

    (headers, body).into_response()
}
