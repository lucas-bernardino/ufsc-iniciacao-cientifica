import os
from dotenv import load_dotenv
import smtplib
from email.mime.text import MIMEText
import imaplib

load_dotenv()
GMAIL_PASSWORD = os.environ.get("GMAIL_PASSWORD", "").replace("_", " ")

def send_email():
    subject = "API"
    body = "URL:http://150.153.214.42:3000"
    sender = "microfoneprojeto@gmail.com"
    recipients = ["microfoneprojeto@gmail.com"]
    password = GMAIL_PASSWORD
    
    msg = MIMEText(body)
    msg['Subject'] = subject
    msg['From'] = sender
    msg['To'] = ', '.join(recipients)
    with smtplib.SMTP_SSL('smtp.gmail.com', 465) as smtp_server:
       smtp_server.login(sender, password)
       smtp_server.sendmail(sender, recipients, msg.as_string())
    print("Message sent!")

def format_raw_email(raw_email):
    content = []
    tmp = ""
    for l in raw_email:
        if l == "\n":
            content.append("".join(tmp))
            tmp = ""
        elif l != "\r": 
            tmp += l
    return content

def get_email():
    mail = imaplib.IMAP4_SSL('imap.gmail.com')
    mail.login('microfoneprojeto@gmail.com', GMAIL_PASSWORD)
    mail.list()
    mail.select("inbox") # connect to inbox.
    
    result, data = mail.search(None, '(FROM "me" SUBJECT "API")' )
    ids = data[0]
    id_list = ids.split() 
    latest_email_id = id_list[-1]
    
    result, data = mail.fetch(latest_email_id, "(RFC822)") 
    raw_email = (data[0][1]).decode("utf-8") 
    content = format_raw_email(raw_email)
  
    if content[-4] != "From: microfoneprojeto@gmail.com" or content[-3] != "To: microfoneprojeto@gmail.com":
        raise Exception("Failed to parse email") 
    
    url = content[-1]
    return url

def change_env_variables(url):
    with open(".env", "r+") as f:
        untouchable = f.readlines()[1].rstrip()
        text_to_write = f"API_URL={url}\n{untouchable}"
        f.truncate()
        f.seek(0)
        f.write(text_to_write)

change_env_variables("httphttp")
#api_url = get_email()
#print(f"API_URL: {api_url}")