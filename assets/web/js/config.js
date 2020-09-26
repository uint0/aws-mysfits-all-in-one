var mysfitsApiEndpoint = 'https://${Token[TOKEN.405]}.execute-api.${Token[AWS.Region.4]}.amazonaws.com/prod/'; // example: 'https://abcd12345.execute-api.us-east-1.amazonaws.com/prod'
var cognitoUserPoolId = '${Token[TOKEN.391]}';  // example: 'us-east-1_abcd12345'
var cognitoUserPoolClientId = '${Token[TOKEN.396]}'; // example: 'abcd12345abcd12345abcd12345'
var awsRegion = '${Token[AWS.Region.4]}'; // example: 'us-east-1' or 'eu-west-1' etc.