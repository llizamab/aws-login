#!/bin/bash

# sh and properties name
script_name=aws-login

# displaying help message
if [ -n "$1" ]
then
  if [ $1 = "help" ]
  then
    printf "Example: \n\t$script_name.sh -c 123456\n\t$script_name.sh -c 123456 -p apside -r us-east-1\n\n"
	printf "\t-c 'number': multifactor code.\n"
	printf "\t-p 'string': (optional) profile name, if not informed use 'default'.\n"
	printf "\t-r 'string': (optional) region, if not informed use 'us-east-1'.\n\n"
	exit
  fi
fi

# checking inpunts parameters
while getopts ":c:p:r:" opt; do
  case $opt in
    c) code="$OPTARG"
    ;;
    p) profile="$OPTARG"
    ;;
    r) region="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
        printf "Example: \n\t$script_name.sh -c 123456\n\t$script_name.sh -c 123456 -p apside -r us-east-1\n\n"
	    printf "\t-c 'number': multifactor code.\n"
	    printf "\t-p 'string': (optional) profile name, if not informed use 'default'.\n"
	    printf "\t-r 'string': (optional) region, if not informed use 'us-east-1'.\n\n"
		exit
    ;;
  esac
done

# check for mfa code
if [ -z "$code" ]
then
  echo "Argument -c not informed. Multifactor code is mandatory."
  exit
fi

# evaluate if use default profile
if [ -z "$profile" ]
then
  profile="default"
fi

# evaluate if use default region
if [ -z "$region" ]
then
  region="us-east-1"
fi

#printf "Argument profile is %s\n" "$profile"
#printf "Argument code is %s\n" "$code"
#printf "Argument region is %s\n" "$region"

# reading properties
SCRIPT=$(readlink -f $0)
SCRIPTPATH=`dirname $SCRIPT`
file="$SCRIPTPATH/$script_name.properties"

if [ -f "$file" ]
then
  echo "Reading properties from file: $file"

  while IFS='=' read -r key value
  do
    key=$(echo $key | tr '.' '_')
    eval ${key}=\${value}
  done < "$file"
  
else
  echo "$file not found."
  exit
fi

mfa_code=$code
aws_account=${aws_account}
user_name=${user_name}
tmp_acces_key_id=${tmp_acces_key_id}
tmp_access_key=${tmp_access_key}

#echo "User aws_account = $aws_account"
#echo "user user_name = $user_name"
#echo "user tmp_acces_key_id = $tmp_acces_key_id"
#echo "user tmp_access_key = $tmp_access_key"

# val parameters
val=0
if [ -z "$aws_account" ]
then
  echo "Properties aws_account not informed."
  val=1
fi
if [ -z "$user_name" ]
then
  echo "Properties user_name not informed."
  val=1
fi
if [ -z "$tmp_acces_key_id" ]
then
  echo "Properties tmp_acces_key_id not informed."
  val=1
fi
if [ -z "$tmp_access_key" ]
then
  echo "Properties tmp_access_key not informed."
  val=1
fi
if [ $val -eq 1 ]
then
  exit
fi


# setting tmp credentials for call sts
set AWS_ACCESS_KEY_ID=$tmp_acces_key_id
set AWS_SECRET_ACCESS_KEY=$tmp_access_key

aws configure set default.aws_access_key_id $tmp_acces_key_id
aws configure set default.aws_secret_access_key $tmp_access_key
aws configure set default.aws_session_token ''


echo "Getting token for user: $user_name, aws account: $aws_account, mfa code: $mfa_code"

# getting token
token_json=$(aws sts get-session-token --serial-number arn:aws:iam::$aws_account:mfa/$user_name --token-code $mfa_code)

# if not error
if [ $? -eq 0 ]
then
	
	# extracting credentials from json sts response
	pat='"AccessKeyId": "(.*)",.* "SecretAccessKey": "(.*)",.*"SessionToken": "(.*)",'
	
	[[ "$token_json" =~ $pat ]]
	
	#echo "${BASH_REMATCH[0]}"
	AccessKeyId=${BASH_REMATCH[1]}
	SecretAccessKey=${BASH_REMATCH[2]}
	SessionToken=${BASH_REMATCH[3]}

	#echo "AccessKeyId: $AccessKeyId "
	#echo "SecretAccessKey: $SecretAccessKey "
	#echo "SessionToken: $SessionToken "
	
	echo "Obtaining token successful!! Setting credentials for profile: $profile"

	# setting credentials for default profile
	if [ $profile = "default" ]
	then
      aws configure set aws_access_key_id $AccessKeyId
      aws configure set aws_secret_access_key $SecretAccessKey
	  aws configure set aws_session_token $SessionToken
	  aws configure set region $region
	else
      aws configure set aws_access_key_id $AccessKeyId --profile $profile
      aws configure set aws_secret_access_key $SecretAccessKey --profile $profile
	  aws configure set aws_session_token $SessionToken --profile $profile
	  aws configure set region $region --profile $profile
	fi

	echo "credentials setted OK. Have a drink!"
	
else
	echo "Obtaining token failed. check for errors."
fi

# removing tmp credentials
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY


