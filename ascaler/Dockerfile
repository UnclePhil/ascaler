FROM docker:20.10.6

LABEL maintainer="koenigphil@gmail.com"

RUN apk update && apk add bash curl jq

WORKDIR /app
COPY ascale.sh ascale.sh
RUN chmod a+x ascale.sh

CMD ["/bin/bash","ascale.sh"]