#!/bin/bash

HELP_MESSAGE="send_sdk [-j|--javascript][-p|--Production][-d|--dev][-i|--ios][-u|--user]<username>[-c|--channel]<channel name>[-cmt|--comment]<message>[-h|--help]"
DIR='/tmp'
DEFAULT_USR='-u firstname1_lastname1'
API_ID='<prod_api_id>'
SDK_TYPE='android'
SDK_POSTFIX=''
PARAMETERS='groupId="com.xxxxx",invokerPackage="com.xxxxx.xxxxxxxx",artifactId="xxxxx-xxxxxxxx",artifactVersion="1.0.0"'
IOS_DEFAULT_USR='firstname2_lastname2'

while [[ $# -gt 0 ]]
do
    key="$1"
    case $key in
        -p|--Production)
        STAGE="Production"
        ;;
        -d|--dev)
        STAGE="dev"
        API_ID='<dev_api_id>'
        ;;
        -j|--javascript)
        SDK_TYPE="javascript"
        ;;
        -i|--ios)
        SDK_TYPE="swift"
        PARAMETERS='classPrefix="XXXXXX"'
        DEFAULT_USR="-u $IOS_DEFAULT_USR"
        ;;
        -u|--user)
        USR="-u $2"
        echo $3
        shift 
        ;;
        -c|--channel)
        CHANNEL="-c $2"
        shift
        ;;
        -d|--dir)
        DIR="$2"
        shift
        ;;
        -cmt|--comment)
        COMMENT="-i $2"
        COMMENT_MSG="with comment \"$2\""
        shift
        ;;
        -h|--help)
        echo $HELP_MESSAGE
        exit 0
        ;;
        *)
        echo $HELP_MESSAGE
        exit 1
        ;;
    esac
    shift # past argument or value
done

if [ -z $STAGE ]; then
        echo "Provide stage"
        echo $HELP_MESSAGE
	exit 1
fi

FILENAME="$DIR/${SDK_TYPE}${SDK_POSTFIX}_sdk_${STAGE}_$(date +%Y-%m-%d_%H_%M_%S).zip"

if [ $SDK_TYPE = "javascript" ]; then
	CMD="aws apigateway get-sdk --rest-api-id $API_ID --stage-name $STAGE --sdk-type $SDK_TYPE $FILENAME --output text"
else
	CMD="aws apigateway get-sdk --rest-api-id $API_ID --stage-name $STAGE --sdk-type $SDK_TYPE --parameters $PARAMETERS $FILENAME --output text"
fi
$CMD>/dev/null

if [ $? -ne 0 ]; then
        echo "aws apigateway exited with error, not sending message"
	exit 1
fi

if [[ -z $USR && -z $CHANNEL ]]; then
	USR=$DEFAULT_USR
fi

SLACK_CMD="slackcat -m $FILENAME $CHANNEL $USR $COMMENT"

MESSAGE="Sending file $FILENAME to ${CHANNEL:3} ${USR:3} $COMMENT_MSG"  
echo $MESSAGE
$SLACK_CMD

if [ $? -eq 0 ]; then
        echo "message sent sucessfully"
else
	echo "message was not sent"        
        exit 1
fi

rm -f $FILENAME
