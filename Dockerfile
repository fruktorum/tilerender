FROM crystallang/crystal:1.7.3-alpine AS build
WORKDIR /app
CMD [ "sh" ]

COPY shard.* ./
RUN mkdir -p /build && shards install

COPY . .
