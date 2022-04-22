FROM debian:bookworm
COPY build.sh /build.sh
ENTRYPOINT ["bash", "/build.sh"]
