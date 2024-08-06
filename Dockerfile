FROM crystallang/crystal:1.13.1-alpine
WORKDIR /app
CMD [ "sh" ]

COPY shard.* ./
RUN mkdir -p /build && shards install

COPY . .
