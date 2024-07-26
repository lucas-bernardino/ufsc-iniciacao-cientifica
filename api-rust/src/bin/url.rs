use dotenv::dotenv;
use lettre::{
    message::header::ContentType, transport::smtp::authentication::Credentials, Message,
    SmtpTransport, Transport,
};
use std::process::{Command, Stdio};

fn main() {
    dotenv().ok();
    let url = get_url().unwrap();
    println!("URL: {url}");
    send_email(&url).unwrap();
}

fn get_url() -> Result<String, Box<dyn std::error::Error + 'static>> {
    let zrok_release = Command::new("zrok")
        .arg("overview")
        .stdout(Stdio::piped())
        .spawn()
        .expect("Failed to spawn zrok overview")
        .wait_with_output()
        .expect("Failed to get output from zrok overview");

    let output = std::str::from_utf8(&zrok_release.stdout)
        .expect("Problem occurred when getting zrok release output")
        .replace(r"\", "");

    let output_json: serde_json::Value = serde_json::from_str(output.as_str()).unwrap();

    Ok(output_json["environments"][1]["shares"]
        .clone()
        .as_array()
        .expect("Failed to get array out of urls")
        .last()
        .expect("Failed to get last element in array")["frontendEndpoint"]
        .to_string())
}

fn send_email(url: &String) -> Result<(), Box<dyn std::error::Error + 'static>> {
    let email = Message::builder()
        .from("microfoneprojeto@gmail.com".parse()?)
        .to("microfoneprojeto@gmail.com".parse()?)
        .subject("API")
        .header(ContentType::TEXT_PLAIN)
        .body(url.clone())?;

    let password = std::env::var("GMAIL_PASSWORD")
        .expect("Missing GMAIL_PASSWORD in .env file!")
        .replace("_", " ");

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
