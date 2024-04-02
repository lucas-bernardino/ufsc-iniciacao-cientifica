use std::process::{Command, Stdio};
use serde::{Deserialize, Serialize};


#[derive(Debug, Deserialize, Serialize)]
struct Body {
    decibels: u16
}

const MIN_DECIBEL: u16 = 700;
const MIN_DECIBEL_STOP: u16 = 620;

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
        Err(e) => panic!("ERROR: {e}") // TODO: Maybe create a POST method that will return the error.
    };

    loop {
        let sensor_data = ctx.read_holding_registers(0x00, 2).await?;
        let decibels_value = ( sensor_data[0] + sensor_data[1] ) / 2;
        
        let body = Body { decibels: decibels_value };
        
        let res = server.post("http://localhost:3000/create")
            .json(&body)
            .send()
            .await?;

        println!("Current decibels: {decibels_value}");

        if decibels_value > MIN_DECIBEL && !is_recording {
            match start_recording(&mut file_count) {
                Ok(pid) => {ffmpeg_pid = pid},
                Err(err) => panic!("ERROR: could not start recording\n{err}") // TODO: Maybe create a POST method that will return the error.
            };
            is_recording = true;
        }

        if decibels_value < MIN_DECIBEL_STOP && is_recording {
            match stop_recording(ffmpeg_pid) {
                Ok(_) => {
                    println!("Stopped recording ffmpeg with PID: {ffmpeg_pid}");
                    is_recording = false;
                },
                Err(err) => {
                    panic!("ERROR: could not stop recording\n{err}"); // TODO: Maybe create a POST method that will return the error.
                } 
            };
            
        }
        
    }

    Ok(())
}

fn check_camera_available() -> Result<(), Box<dyn std::error::Error>> {
    
    let v4l2_command = Command::new("v4l2-ctl")
        .arg("--list-devices")
        .output()?;

    let output = String::from_utf8(v4l2_command.stderr)?;

    if output.len() != 0 {
        return Err(output.into());
    }
    
    Ok(())
}

fn start_recording(count: &mut u16) -> Result<u32, Box<dyn std::error::Error>>  {
    
    let format_count = format!("out{}.mkv", count);

    let ffmpeg_command = Command::new("ffmpeg")
        .args(["-f", "v4l2", "-framerate", "30", "-video_size", "1280x720", "-input_format", "mjpeg", "-i", "/dev/video0", "-c", "copy", &format_count])
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .stdin(Stdio::null())
        .spawn();

    let id = ffmpeg_command?.id();

    *count += 1;

    Ok(id)
}

fn stop_recording(ffmpeg_pid: u32) -> Result<(), Box<dyn std::error::Error>> {

    Command::new("kill")
        .arg(format!("{}", ffmpeg_pid))
        .spawn()?;

    Ok(())
    
}
