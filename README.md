
# aws-login

AWS MFA automation script for aws-cli operations.

If you use a policy with [BoolIfExists{"aws:MultiFactorAuthPresent": "false"}](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_examples_aws_my-sec-creds-self-manage.html) to ensure users use MFA on console, they api calls through the aws-cli will give AccessDenied error.
This happen cause aws-cli use the long terms credentials where MultiFactorAuthPresent doesnt exists.
In that case this users have to use temporary credentials with [STS](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html), so, this script automate those tasks doing the following:


 1. Execute aws configure with credentials who have to had permissions to call aws sts get-session-token command
 2. Execute the aws sts get-session-token command for a user, passing as parameter the mfa code
 3. Extract from the json response the temporary credentials
 4. Execute aws configure for those temporary credentials and optionally for a specific profile


## Properties definitions

Before execute, edit the next values on file aws-login.properties:

- aws_account = aws account number
- user_name = name of the user who use aws-cli
- tmp_acces_key_id = aws_access_key_id with permissions to invoke: aws sts get-session-token
- tmp_access_key = aws_secret_access_key with permissions to invoke: aws sts get-session-token


## Usage

```
./aws-login.sh help

Example:
        aws-login.sh -c 123456
        aws-login.sh -c 123456 -p apside -r us-east-1

        -c 'number': multifactor code.
        -p 'string': (optional) profile name, if not informed use 'default'.
        -r 'string': (optional) region, if not informed use 'us-east-1'.

```


## References:
- [authenticate-mfa-cli](https://aws.amazon.com/es/premiumsupport/knowledge-center/authenticate-mfa-cli/)
- [aws cli](https://docs.aws.amazon.com/cli/latest/reference/configure/)
- [users manage mfa](https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_users-self-manage-mfa-and-creds.html)
