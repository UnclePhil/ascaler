FRFROM docker:20.10.6

LABEL maintainer="koenigphil@gmail.com"

RUN apk update && apk add curl jq

COPY auto-scale.sh /auto-scale.sh
RUN chmod a+x /auto-scale.sh

CMD ["/auto-scale.sh"]