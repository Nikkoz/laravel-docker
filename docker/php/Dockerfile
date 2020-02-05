FROM php:7.3.13-fpm

ARG CURRENT_USER

# Install dependencies
RUN apt-get -qq update && apt-get -qq install -y \
    autoconf \
    cmake \
    file \
    libc-dev \
    make \
    pkgconf \
    build-essential \
    libmcrypt-dev \
    libpq-dev \
    git \
    vim nano \
    zip \
    unzip \
    openssl \
    zlib1g-dev \
    libzip-dev \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    locales \
    sqlite3 \
    jpegoptim optipng pngquant gifsicle \
    libsqlite3-dev  \
    curl \
    libxml2-dev

# Clear cache
RUN rm -rf /var/lib/apt/lists/*

RUN apt-get update -yqq \
    && apt-get install -y apt-utils wget git unzip \
    && pecl channel-update pecl.php.net \
    && pecl install xdebug-2.9.0

# Install extensions
RUN docker-php-ext-configure gd --with-gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/ \
    && docker-php-ext-configure soap \
    && docker-php-ext-install pdo pdo_pgsql zip mbstring tokenizer bcmath \
    && docker-php-ext-install -j$(nproc) gd soap iconv \
    && docker-php-ext-enable xdebug

# install redis
RUN pecl install -o -f redis \
    &&  rm -rf /tmp/pear \
    &&  echo "extension=redis.so" > /usr/local/etc/php/conf.d/redis.ini

# Copy configuration
COPY ./local.ini /usr/local/etc/php/php.ini

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ --filename=composer

RUN pear install PHP_CodeSniffer

RUN /usr/local/bin/phpcs --config-set show_progress 1 && \
    /usr/local/bin/phpcs --config-set colors 1 && \
    /usr/local/bin/phpcs --config-set report_width 140 && \
    /usr/local/bin/phpcs --config-set encoding utf-8 && \
    /usr/local/bin/phpcs --config-set severity 1

# Set working directory
WORKDIR /var/www

# Clean
RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/* \
    && chown -R ${CURRENT_USER} /var/www
