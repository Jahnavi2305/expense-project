#!/bin/bash

R="\e[31m"  #to print red colour
G="\e[32m"  #to print green  colour
Y="\e[33m"  #to print yellow colour

LOGS_FOLDER="/var/log/expense"  #to store logs in this expense directory
SCRIPT_NAME=$(echo $0 | cut -d "." -f1) #this will return the folder name 
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S) #this is to craete a timestamp
LOG_FILE="$LOGS_FOLDRE/$SCRIPT_NAME-$TIMESTAMMP.log"  #logfloder , scriptname,timestamp are together

mkdir -p $LOGS_FOLDER #this is to create log folder  -p : is used if this already a director with same name then it will not craete if there is no directory with this name then directory is created

USERID=$(id -u) #will give the used id id it is sudo then O or 1001 /1002..

CHECK_ROOT(){    #this function is to check whether command is run with root access or not , if not exit
   
    if [ $USERID -ne 0 ]
    then
        echo -e "$R Please run this script with root priveleges $N" | tee -a $LOG_FILE
        exit 1
    fi
}

VALIDATE(){
    if [ $1 -ne 0 ]
    then 
       echo -e "$2 is $R FALIED $N" | tee -a $LOG_FILE  #tee command is used to prit log in terminal and in log folder
    exit 1
    else
        echo -e "$2 is $R SUCCESS $N" &>> $LOG_FILE
    fi

}

echo "Script started executing at: $(date)" | tee -a $LOG_FILE
CHECK_ROOT
dnf install nginx -y &>>LOG_FILE
VALIDATE $? "Installing Nginx"

systemctl enable nginx  &>>LOG_FILE
VALIDATE $? "Enable Nginx"

systemctl start nginx &>>LOG_FILE
VALIDATE $? "start Nginx"

rm -rf /usr/share/nginx/html/* &>>LOG_FILE  #by default when we run ip address we get red hat page , we will be removing that default page 
VALIDATE $? "removing default website"

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip &>>$LOG_FILE
VALIDATE $? "Downloding frontend code"

cd /usr/share/nginx/html  #we will be going into that directory and downloag

unzip /tmp/frontend.zip &>>$LOG_FILE  #extract the frontend code
VALIDATE $? "Extract frontend code"

cp /home/ec2-user/expense-project/expense.conf /etc/nginx/default.d/expense.conf
VALIDATE $? "Copied expense conf"

systemctl restart nginx &>>$LOG_FILE
VALIDATE $? "Restarted Nginx"

