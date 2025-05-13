FROM php:8.4-fpm AS builder

RUN apt-get update && apt-get install -y \
    git unzip curl supervisor libpq-dev libicu-dev libzip-dev libonig-dev \
    libfreetype6-dev libjpeg-dev libpng-dev zlib1g-dev libxml2-dev && \
    docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ && \
    docker-php-ext-install -j$(nproc) gd pdo pdo_pgsql mbstring intl zip exif sockets opcache pcntl && \
    pecl install redis apcu && docker-php-ext-enable redis apcu && \
    rm -rf /var/lib/apt/lists/*

ENV TZ=Europe/Moscow

ARG USER_ID=1000
ARG GROUP_ID=1000

RUN groupadd -g ${GROUP_ID} appuser && useradd -u ${USER_ID} -g appuser -m appuser

RUN curl -sS https://getcomposer.org/installer -o composer-setup.php && \
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer && \
    rm composer-setup.php

RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -E - && \
    apt-get update && apt-get install -y nodejs && \
    npm install -g yarn && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/www/.yarn /var/www/.cache/yarn && \
    touch /var/www/.yarnrc && \
    chown -R appuser:appuser /var/www/.yarn /var/www/.cache/yarn /var/www/.yarnrc /var/www && \
    chmod 644 /var/www/.yarnrc && \
    chmod -R 775 /var/www/.yarn /var/www/.cache/yarn /var/www

WORKDIR /var/www/html

COPY ./docker/php/php.ini /usr/local/etc/php/php.ini
COPY ./docker/php/www.conf /usr/local/etc/php-fpm.d/www.conf

RUN mkdir -p storage/logs && chown -R appuser:appuser storage && chmod -R 775 storage

COPY --chown=appuser:appuser . /var/www/html

USER appuser

EXPOSE 9000

COPY ./docker/supervisor/supervisord.conf /etc/supervisor/supervisord.conf
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
