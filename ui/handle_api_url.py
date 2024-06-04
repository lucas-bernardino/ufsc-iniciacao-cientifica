import os
from dotenv import load_dotenv
import smtplib
from email.mime.text import MIMEText

load_dotenv()
GMAIL_PASSWORD = os.environ.get("GMAIL_PASSWORD", "")

subject = "API"
body = "HEYYYY JUDE"
sender = "microfoneprojeto@gmail.com"
recipients = ["microfoneprojeto@gmail.com"]
password = GMAIL_PASSWORD

def send_email(subject, body, sender, recipients, password):
    msg = MIMEText(body)
    msg['Subject'] = subject
    msg['From'] = sender
    msg['To'] = ', '.join(recipients)
    with smtplib.SMTP_SSL('smtp.gmail.com', 465) as smtp_server:
       smtp_server.login(sender, password)
       smtp_server.sendmail(sender, recipients, msg.as_string())
    print("Message sent!")


send_email(subject, body, sender, recipients, password)