use dotenv::dotenv;
use lettre::{
    message::header::ContentType, transport::smtp::authentication::Credentials, Message,
    SmtpTransport, Transport,
};

#[tokio::main]
async fn main() {
    dotenv().ok();

    let url = String::from("umaurl");

    send_email(&url).await.unwrap();
}

async fn send_email(url: &String) -> Result<(), Box<dyn std::error::Error + 'static>> {
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
