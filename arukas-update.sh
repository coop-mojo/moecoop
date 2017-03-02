#!/bin/sh

arukas_container_update()
{
    local img=$1
    local ver=$2
    local dom=$3
    str=$(curl -sn https://app.arukas.io/api/containers -H "Content-Type: application/vnd.api+json" -H "Accept: application/vnd.api+json")
    echo "str: $str"
    local cid=$(echo $str | jq ".data[] | select(.attributes.arukas_domain == \"$dom\") | .id" | sed 's/"//g')

    curl -sn -X PATCH https://app.arukas.io/api/containers/$cid \
  -d "{
  \"data\": {
    \"type\": \"containers\",
    \"attributes\": {
      \"image_name\": \"$img:$ver\",
      \"instances\": 5,
      \"ports\": [
        {
          \"number\": 8080,
          \"protocol\": \"tcp\"
        }
      ],
      \"arukas_domain\": \"$dom\"
    }
  }
}" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" || exit 1
}

arukas_container_update $1 $2 $3
