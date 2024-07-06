FROM rust:latest

COPY ./src ./src
COPY ./Cargo.lock .
COPY ./Cargo.toml .
COPY .env .
COPY ./.sqlx ./.sqlx

ARG DATABASE_URL

ENV DATABASE_URL=$DATABASE_URL

RUN cargo install sqlx-cli --no-default-features --features postgres

ENV SQLX_OFFLINE=true

RUN cargo build

CMD cargo run
