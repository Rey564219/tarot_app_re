FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app/frontend
COPY frontend/pubspec.yaml frontend/pubspec.lock ./
RUN flutter pub get

COPY frontend /app/frontend
RUN flutter build web --release

FROM nginx:1.25-alpine
COPY deploy/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/frontend/build/web /usr/share/nginx/html

EXPOSE 80
