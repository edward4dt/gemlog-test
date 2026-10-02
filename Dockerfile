# 超輕量 Agate 執行映像檔（< 20MB）
# 使用 musl 靜態連結版本，搭配 alpine 可得到極小的拋棄式容器
FROM alpine:latest

RUN apk add --no-cache wget ca-certificates \
    && wget -O agate.tar.gz https://github.com/mbrubeck/agate/releases/latest/download/agate-x86_64-unknown-linux-musl.tar.gz \
    && tar -xvf agate.tar.gz -C /usr/local/bin/ \
    && rm agate.tar.gz

WORKDIR /app
# 只把 Gemtext 內容複製進映像檔，並排除 Git 與 CI 設定等無關檔案
COPY index.gmi /app/content/
COPY posts/ /app/content/posts/
# 避免將 .github / Dockerfile / fly.toml 等非內容檔案打包進膠囊
RUN rm -rf /app/content/.github /app/content/Dockerfile /app/content/fly.toml

# 宣告對外開放 Gemini 協定 Port 1965
EXPOSE 1965

CMD ["agate", "--content", "/app/content", "--certs", "/app/certs", "--hostname", "yourdomain.tw", "--lang", "zh-TW"]
