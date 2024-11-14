 #!/bin/bash
LOGS_FOLDER="/var/log/expense"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME-$TIMESTAMP.log"
mkdir -p $LOGS_FOLDER

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
N="\e[0m"
Y="\e[33m"

CHECK_ROOT(){
    if [ $USERID -ne 0 ]
    then
        echo -e "$R Please run this script with root priveleges $N" | tee -a $LOG_FILE
        exit 1
    fi
}

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 is...$R FAILED $N"  | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 is... $G SUCCESS $N" | tee -a $LOG_FILE
    fi
}

echo "Script started executing at: $(date)" | tee -a $LOG_FILE

dnf module disable nodejs -y &>>LOG_FILE #redirecting logs to log file
VALIDATE $? "disable default nodejs"

dnf module enable nodejs:20 -y &>>LOG_FILE
VALIDATE $? "enabling nodejs:20"

dnf install nodejs -y &>>LOG_FILE
VALIDATE $? "Install nodejs"

#userid will be craeted when we run the command on terminal which creates IDEMPOTENCY
#so we check in the if condition
#id expense , if this command has userid it will return O so userid will not be craeted again...if id expense has no such user , this will create expense user
id expense &>>LOG_FILE
if [ $? -ne 0 ]
then 
echo -e " $Y creating user $N " &>>LOG_FILE
useradd expense 
VALIDATE $? "Creating expense user"
else
echo "user is already craeted ..please check.. $R skipping $N" &>>LOG_FILE
fi

mkdir -p /app #we are crating a directory ..so -p is used if directory already exists app directory will not be created or else directory will be created.
 VALIDATE $? "Creating /app folder"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE  # curl command is used to download the content in the file

VALIDATE $? "Downloading the backend application"

cd /app
rm -rf /app/*  #if multiple times code is downloaded like may be version upadate like that...existing version will be removed and new will be downloaded with this command ...remove the existing code
unzip /tmp/backend.zip &>>LOG_FILE
VALIDATE $? "Exatracing backend application code"

npm install #all the dependencies are dowmloaded

cp /home/ec2-user/expense-project/backend.service /etc/systemd/system/backend.service


#load the data before running the backend

#this will connect 
dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "Installing MySQL Client"

mysql -h mysql.devops20lpa.online -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$LOG_FILE
VALIDATE $? "Schema loading"  #database is craeted

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Daemon reload"

systemctl enable backend &>>$LOG_FILE
VALIDATE $? "Enabled backend"

systemctl restart backend &>>$LOG_FILE
VALIDATE $? "Restarted Backend"


















