use std::sync::Arc;

use axum::{extract::State, http::StatusCode, response::IntoResponse, Json};

use crate::models::{CreateMicrophoneSchema, MicrophoneModel};
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
