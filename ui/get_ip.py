import os
from dotenv import load_dotenv
import smtplib
from email.mime.text import MIMEText
import imaplib

load_dotenv()
GMAIL_PASSWORD = os.environ.get("GMAIL_PASSWORD", "").replace("_", " ")

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

    result, data = mail.search(None, '(FROM "me" SUBJECT "IP")' )
    ids = data[0]
    id_list = ids.split()
    latest_email_id = id_list[-1]

    result, data = mail.fetch(latest_email_id, "(RFC822)")
    raw_email = (data[0][1]).decode("utf-8")
    content = format_raw_email(raw_email)

    url = content[-1]
    return url

#get_email()
#send_email()
if __name__ == "__main__":
    print(get_email())