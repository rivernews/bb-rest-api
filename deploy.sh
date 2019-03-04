cd terraform && \
terraform plan || return
cd ..

if [[ $1 != '' ]]
then
    git add .
    git commit -m "${1:-fix}"
    git push
fi

. ./venv/bin/activate && \
$(aws ecr get-login --no-include-email --region us-east-2) && \
docker-compose up -d --build --remove-orphans && \
docker-compose push && \
cd terraform && \
terraform apply && \
cd .. && \
echo "SUCCESS! Allow several minutes for change to take effect on production server. Take some rest and have a cup of coffee! Then go to the url and check it out." && return

echo ERROR: see bove message.