FROM debian:bullseye-slim
COPY build.sh /build.sh
ENTRYPOINT ["bash", "/build.sh"]
