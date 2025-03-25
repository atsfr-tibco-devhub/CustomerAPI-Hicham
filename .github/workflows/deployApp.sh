# BASE URL
BASE_URL=$BASE_URL
# Key:
TOKEN=$PLATFORM_TOKEN
# Flogo File to Deploy
FLOGO_FILE=$FILE_TO_DEPLOY
APP_NAME=$APPLICATION_NAME
#Owner to use in tags
OWNER=$GITHUB_USER

# Testing the API
echo "Testing Connection ..."
BUILD_VERSION=$(curl -s -X 'GET' \
  "$BASE_URL/public/v1/dp/flogoversions" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-Atmosphere-Token: $TOKEN" | jq -r  '.totalBuildtypes') 

if [[ -z "$BUILD_VERSION" ]]; then echo "Not able to connect to TIBCO Platform API !" && exit 1; else echo "Connection Successful !"; fi

# Create a build
echo "Creating a build..."
# Get the build ID
BUILD_ID=$(curl -s -X 'POST' \
  "$BASE_URL/public/v1/dp/builds" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: multipart/form-data' \
  -H "X-Atmosphere-Token: $TOKEN" \
  -F "app.json=@$FLOGO_FILE" | jq -r  '.buildId')
echo "BuildID: $BUILD_ID "
sleep 5

# Deploy app using buildId (scale to 1)
output=$(curl -s -X 'POST' \
  "$BASE_URL/public/v1/dp/builds/$BUILD_ID/deploy" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -H "X-Atmosphere-Token: $TOKEN" \
  -d "{\"appId\":\"\",\"buildId\":\"$BUILD_ID\",\"eula\":true,\"appName\":\"$APP_NAME\",\"tags\":[\"$OWNER\"],\"replicas\": 1,\"resourceLimits\":{\"limits\":{\"cpu\":\"500m\",\"memory\":\"512Mi\"},\"requests\":{\"cpu\":\"125m\",\"memory\":\"256Mi\"}},\"enableServiceMesh\":false,\"enableAutoscaling\":false}")
echo $output
APP_ID=$(echo $output | jq -r  '.appId')
if [[ -z "$APP_ID" ]]; then 
  echo "Error deploying the application: \n$output" && exit 1; 
fi
sleep 5 
echo "Application deployed with APP ID: $APP_ID: \n$output"
