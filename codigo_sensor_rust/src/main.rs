
use serde::{Deserialize, Serialize};


#[derive(Debug, Deserialize, Serialize)]
struct Body {
    decibels: u16
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

    loop {
        let sensor_data = ctx.read_holding_registers(0x00, 2).await?;
        let decibels_value = ( sensor_data[0] + sensor_data[1] ) / 2;
        
        let body = Body { decibels: decibels_value };
        
        let res = server.post("http://localhost:3000/create")
            .json(&body)
            .send()
            .await?;
        
        println!("Printing res: {res:#?}");
    }

    Ok(())
}
