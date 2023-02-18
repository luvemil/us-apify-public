PAYLOAD=$1

sed -i.bak -e "s/WORKSPACE/$WORKSPACE/" -e "s/MESSAGE/$MESSAGE/" $1

curl \
    --header "Authorization: Bearer $TF_TOKEN" \
    --header "Content-Type: application/vnd.api+json" \
    --request POST \
    --data @$1 \
    https://app.terraform.io/api/v2/runs
