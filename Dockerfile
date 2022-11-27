FROM nginx:1-alpine

COPY ["etc/", "/etc/"]
COPY ["html/", "/usr/share/nginx/html/"]
