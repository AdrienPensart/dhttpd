import std.socket;
import std.traits;

import tracer;
import log;

class SmtpClient
{
    public:

        this(string host, ushort port)
        {
            mixin (Tracer);
            client = new TcpSocket(new InternetAddress(host, port));
            client.send("HELO " ~ host ~ "\r\n");
            char[4096] receiveBuffer;
            auto size = client.receive(receiveBuffer);
            lout.info("Response : ", receiveBuffer[0..size]);
        }

        ~this()
        {
            mixin (Tracer);
            if(!(client is null))
            {
                if(client.isAlive)
                {
                    client.send("QUIT\r\n");
                    char[4096] receiveBuffer;
                    auto size = client.receive(receiveBuffer);
                    lout.info("Response : ",receiveBuffer[0..size]);
                    client.close();
                }
            }
        }

        bool send(Email m)
        {
            mixin (Tracer);
            if(m.isValid())
            {
                string raw = m.format();
                lout.info("Message : ", raw);
                client.send(raw);
                char[4096] receiveBuffer;
                auto size = client.receive(receiveBuffer);
                lout.log("Response : ",receiveBuffer[0..size]);
                return true;
            }
            return false;
        }

    private:

        Socket client;
}

enum RecipientType { NORMAL, CC, BCC };

class Email
{
    public:

        bool setXmailer(string xmailer)
        {
            return setEmailProperty(this.xmailer,xmailer);
        }

        void setBody(string messageBody)
        {
            this.messageBody = messageBody;
        }

        void setSubject(string messageSubject)
        {
            this.messageSubject = messageSubject;
        }

        void setFromName(string fromName)
        {
            this.fromName = fromName;
        }

        auto getFromEmail()
        {
            return fromEmail;
        }

        bool setFromEmail(string fromEmail)
        {
            return setEmailProperty(this.fromEmail,fromEmail);
        }

        bool setReplyTo(string replyTo)
        {
            return setEmailProperty(this.replyTo,replyTo);
        }

        void addRecipient(string recipient, RecipientType rt = RecipientType.NORMAL)
        {
            recipients[rt] ~= recipient;
        }

        string[] getRecipients()
        {
            return recipients[RecipientType.NORMAL];
        }

        string[] getRecipientsCC()
        {
            return recipients[RecipientType.CC];
        }

        string[] getRecipientsBCC()
        {
            return recipients[RecipientType.BCC];
        }    

        bool isValid()
        {
            return fromEmail.length && 
                   messageSubject.length && 
                   messageBody.length && 
                   (recipients[RecipientType.NORMAL].length  || 
                    recipients[RecipientType.CC].length || 
                    recipients[RecipientType.BCC].length);
        }

        string format()
        {
            mixin (Tracer);

            string raw;
            raw ~= "To: ";
            foreach(i, recipient; recipients[RecipientType.NORMAL])
            {
                raw ~= (i > 0 ? "," : "") ~ recipient;
            }

            raw ~= "\r\nCc: \0";
            foreach(i, recipient; recipients[RecipientType.CC])
            {
                raw ~= (i > 0 ? "," : "") ~ recipient;
            }
            
            foreach(i, recipient; recipients[RecipientType.BCC])
            {
                raw ~= recipient ~ (i > 0 ? "," : "");
            }
            raw ~= "\r\nBcc\0";

            return raw;
        }

    private:

        bool setEmailProperty(ref string property, string value)
        {
            property = value;
            return true;
        }

        string xmailer;
        string messageSubject;
        string messageBody;
        string fromName;
        string fromEmail;
        string replyTo;
        string[][RecipientType] recipients;
}

