use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

#[derive(Debug, FromRow, Deserialize, Serialize)]
#[allow(non_snake_case)]
pub struct MicrophoneModel {
    pub id: Uuid,
    pub decibels: f32,
    #[serde(rename = "createdAt")]
    pub created_at: Option<chrono::DateTime<chrono::Utc>>,
    #[serde(rename = "updatedAt")]
    pub updated_at: Option<chrono::DateTime<chrono::Utc>>,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct CreateMicrophoneSchema {
    pub decibels: f32,
}

#[derive(Debug, Deserialize)]
pub struct Filter {
    pub min: Option<f32>,
    pub limit: Option<i64>,
    pub ordered: Option<String>,
}
