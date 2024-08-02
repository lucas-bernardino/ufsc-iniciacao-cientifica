use futures_util::FutureExt;
use rust_socketio::{asynchronous::ClientBuilder, Payload};
use serde::{Deserialize, Serialize};
use std::{
    process::{Command, Stdio},
    sync::Arc,
};

use reqwest::header::{CONTENT_DISPOSITION, CONTENT_TYPE};

use tokio_util::io::ReaderStream;

#[derive(Debug, Deserialize, Serialize)]
struct Body {
    decibels: u16,
}

#[tokio::main(flavor = "current_thread")]
#[allow(unreachable_code)]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    use tokio_serial::SerialStream;

    use tokio_modbus::prelude::*;

    let tty_path = "/dev/ttyUSB0";
    let slave = Slave(0x01);

    let builder = tokio_serial::new(tty_path, 4800);
    let port = SerialStream::open(&builder).unwrap();
    let mut ctx = rtu::attach_slave(port, slave);

    let server = reqwest::Client::new();

    let mut is_recording: bool = false;

    let mut ffmpeg_pid = 0;

    let mut file_count: u16 = 0;

    match check_camera_available() {
        Ok(_) => println!("Found camera."),
        Err(e) => panic!("ERROR: {e}"), // TODO: Maybe create a POST method that will return the error.
    };

    let mut min_decibeis = Arc::new(tokio::sync::Mutex::new(600));
    let mut max_decibeis = Arc::new(tokio::sync::Mutex::new(700));

    let min_decibeis_cloned = Arc::clone(&min_decibeis);
    let max_decibeis_cloned = Arc::clone(&max_decibeis);

    let callback = move |payload: Payload, socket: rust_socketio::asynchronous::Client| {
        let min_cloned = Arc::clone(&min_decibeis_cloned);
        let max_cloned = Arc::clone(&max_decibeis_cloned);

        async move {
            let mut data = String::from("");
            match payload {
                Payload::Text(text) => data = text.first().unwrap().to_string(),
                _ => {}
            }
            let data = data.trim_matches('"');
            let parsed_data = data.split(",").collect::<Vec<&str>>();
            let min = parsed_data
                .get(0)
                .unwrap()
                .replace("min:", "")
                .parse::<u16>()
                .unwrap();
            let max = parsed_data
                .get(1)
                .unwrap()
                .replace("max:", "")
                .parse::<u16>()
                .unwrap();
            println!("Sucessfully got: {} and {}", min, max);
            *min_cloned.lock().await = min;
            *max_cloned.lock().await = max;
        }
        .boxed()
    };


    println!("Antes de se conectar");

    ClientBuilder::new("http://localhost:3000")
        .namespace("")
        .on("update", callback)
        .connect()
        .await
        .expect("Connection failed");

    println!("Depois de se conectar");

    std::thread::sleep(std::time::Duration::from_secs(3));

    loop {
        let sensor_data = ctx.read_holding_registers(0x00, 2).await?;
        let decibels_value = (sensor_data[0] + sensor_data[1]) / 2;

        let body = Body {
            decibels: decibels_value,
        };

        let res = server
            .post("http://localhost:3000/create")
            .json(&body)
            .send()
            .await?;

        let min_db = min_decibeis.lock().await;
        let max_db = max_decibeis.lock().await;

        println!("Current decibels: {decibels_value}. Min - {min_db} and Max - {max_db}");

        if decibels_value > *max_db && !is_recording {
            match start_recording() {
                Ok(pid) => {
                    ffmpeg_pid = pid;
                    println!("Started recording!");
                }
                Err(err) => panic!("ERROR: could not start recording\n{err}"), // TODO: Maybe create a POST method that will return the error.
            };
            is_recording = true;
        }

        if decibels_value < *min_db && is_recording {
            match stop_recording(ffmpeg_pid) {
                Ok(_) => {
                    println!("Stopped recording ffmpeg with PID: {ffmpeg_pid}");
                    is_recording = false;
                    post_video(&server).await;
                }
                Err(err) => {
                    panic!("ERROR: could not stop recording\n{err}"); // TODO: Maybe create a POST method that will return the error.
                }
            };
        }
    }

    Ok(())
}

fn check_camera_available() -> Result<(), Box<dyn std::error::Error>> {
    let v4l2_command = Command::new("v4l2-ctl").arg("--list-devices").output()?;

    let output = String::from_utf8(v4l2_command.stderr)?;

    if output.len() != 0 {
        return Err(output.into());
    }

    Ok(())
}

fn start_recording() -> Result<u32, Box<dyn std::error::Error>> {
    let ffmpeg_command = Command::new("ffmpeg")
        .args([
            "-f",
            "v4l2",
            "-framerate",
            "30",
            "-video_size",
            "1280x720",
            "-input_format",
            "mjpeg",
            "-i",
            "/dev/video0",
            "-c",
            "copy",
            "out.mkv",
        ])
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .stdin(Stdio::null())
        .spawn();

    let id = ffmpeg_command?.id();

    Ok(id)
}

fn stop_recording(ffmpeg_pid: u32) -> Result<(), Box<dyn std::error::Error>> {
    Command::new("kill")
        .arg(format!("{}", ffmpeg_pid))
        .spawn()?;

    Ok(())
}

async fn post_video(server: &reqwest::Client) -> Result<(), Box<dyn std::error::Error>> {
    let file = match tokio::fs::File::open("out.mkv").await {
        Ok(f) => f,
        Err(e) => match e.kind() {
            std::io::ErrorKind::NotFound => {
                std::thread::sleep(std::time::Duration::from_secs(5));
                println!("Vou deletar o arquivo");
                tokio::fs::remove_file("out.mkv").await.unwrap();
                println!("Deletei");
                return Ok(());
            }
            _ => return Err(e)?,
        },
    };

    let stream = ReaderStream::new(file);

    let body_stream = reqwest::Body::wrap_stream(stream);

    let response = server
        .post("http://localhost:3000/video")
        .header(CONTENT_TYPE, "video/webm")
        .header(CONTENT_DISPOSITION, "attachment; filename=out.mkv")
        .body(body_stream)
        .send();

    Command::new("rm").arg("out.mkv").spawn()?;

    println!("Response is: {x:#?}", x = response.await);

    Ok(())
}
