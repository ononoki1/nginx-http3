FROM debian:bullseye
COPY build.sh /build.sh
ENTRYPOINT ["bash", "/build.sh"]
