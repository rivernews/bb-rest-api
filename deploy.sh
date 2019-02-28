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
cd .. && return

echo ERROR: see bove message.