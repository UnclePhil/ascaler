FRFROM docker:20.10.6

LABEL maintainer="koenigphil@gmail.com"

RUN apk update && apk add curl jq

COPY ascale.sh /ascale.sh
RUN chmod a+x /ascale.sh

CMD ["/ascale.sh"]